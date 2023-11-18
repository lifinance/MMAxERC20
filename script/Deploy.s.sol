// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.20;

import "forge-std/Script.sol";

/// local imports
import {WormholeSenderAdapter} from "src/adapters/wormhole/WormholeSenderAdapter.sol";
import {WormholeReceiverAdapter} from "src/adapters/wormhole/WormholeReceiverAdapter.sol";

import {AxelarSenderAdapter} from "src/adapters/axelar/AxelarSenderAdapter.sol";
import {AxelarReceiverAdapter} from "src/adapters/axelar/AxelarReceiverAdapter.sol";

import {GAC} from "src/controllers/GAC.sol";
import {MessageSenderGAC} from "src/controllers/MessageSenderGAC.sol";
import {MessageReceiverGAC} from "src/controllers/MessageReceiverGAC.sol";
import {xERC20} from "src/token/xERC20.sol";

import {MultiBridgeMessageSender} from "src/MultiBridgeMessageSender.sol";
import {MultiBridgeMessageReceiver} from "src/MultiBridgeMessageReceiver.sol";

contract DeployScript is Script {
    bytes32 _salt = keccak256(abi.encode("MMA_TOKEN_DEPLOYMENT_3"));

    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint256 privKey = vm.envUint("PRIVATE_KEY");

    uint256 constant BSC_CHAIN_ID = 56;
    uint256 constant AVA_CHAIN_ID = 43114;

    uint256[] public ALL_CHAINS = [BSC_CHAIN_ID, AVA_CHAIN_ID];

    /// @dev constants for wormhole
    address constant BSC_RELAYER = 0x27428DD2d3DD32A4D7f7C497eAaa23130d894911;
    address constant AVA_RELAYER = 0x27428DD2d3DD32A4D7f7C497eAaa23130d894911;

    /// @dev constants for axelar
    address constant BSC_GATEWAY = 0x304acf330bbE08d1e512eefaa92F6a57871fD895;
    address constant AVA_GATEWAY = 0x5029C0EFf6C34351a0CEc334542cDb22c7928f78;

    address constant BSC_GAS_SERVICE = 0x2d5d7d31F671F86C782533cc367F14109a082712;
    address constant AVA_GAS_SERVICE = 0x2d5d7d31F671F86C782533cc367F14109a082712;

    /// @notice configure all wormhole parameters in order of DST_CHAINS
    address[] public WORMHOLE_RELAYERS = [BSC_RELAYER, AVA_RELAYER];
    uint16[] public WORMHOLE_CHAIN_IDS = [4, 6];

    /// @notice configure all axelar parameters in order of DST_CHAINS
    address[] public AXELAR_GATEWAYS = [BSC_GATEWAY, AVA_GATEWAY];
    address[] public AXELAR_GAS_SERVICES = [BSC_GAS_SERVICE, AVA_GAS_SERVICE];
    string[] public AXELAR_CHAIN_IDS = ["binance", "avalanche"];

    /// @dev maps the local chain id to a fork id
    mapping(uint256 => uint256) public fork;

    /// @dev maps the contract chain and name to an address
    mapping(uint256 => mapping(bytes => address)) public contractAddress;

    function run() external {
        _deploy();
    }

    /*///////////////////////////////////////////////////////////////
                                SETUP
    //////////////////////////////////////////////////////////////*/
    function _deploy() internal {
        /// @dev create forks of 2 diff chains
        fork[BSC_CHAIN_ID] = vm.createSelectFork(vm.envString("BSC_FORK_URL"));

        fork[AVA_CHAIN_ID] = vm.createSelectFork(vm.envString("AVA_FORK_URL"));

        /// @dev deploys the gac contracts
        _deployGac();

        /// @dev deploys amb adapters
        _deployWormholeAdapters();
        _deployAxelarAdapters();

        /// @dev deploys mma sender and receiver adapters
        _deployCoreContracts();

        /// @dev setup core contracts
        _setupCoreContracts();

        /// @dev setup amb adapters
        _setupAdapters();
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL HELPERS
    //////////////////////////////////////////////////////////////*/
    function _deployGac() internal {
        for (uint256 i; i < ALL_CHAINS.length; ++i) {
            uint256 chainId = ALL_CHAINS[i];
            vm.selectFork(fork[chainId]);
            vm.startBroadcast(privKey);

            contractAddress[chainId][bytes("SENDER_GAC")] = address(new MessageSenderGAC{salt: _salt}(vm.addr(privKey)));
            contractAddress[chainId][bytes("RECEIVER_GAC")] =
                address(new MessageReceiverGAC{salt: _salt}(vm.addr(privKey)));
            vm.stopBroadcast();
        }
    }

    function _deployWormholeAdapters() internal {
        uint256 len = ALL_CHAINS.length;

        /// @notice deploy receiver adapters to all DST_CHAINS
        address[] memory _receiverAdapters = new address[](len);

        for (uint256 i; i < len;) {
            uint256 chainId = ALL_CHAINS[i];
            vm.selectFork(fork[chainId]);
            vm.startBroadcast(privKey);

            contractAddress[chainId][bytes("WORMHOLE_SENDER_ADAPTER")] = address(
                new WormholeSenderAdapter{salt: _salt}(
                    WORMHOLE_RELAYERS[i],
                    contractAddress[chainId][bytes("SENDER_GAC")]
                )
            );
            address receiverAdapter = address(
                new WormholeReceiverAdapter{salt: _salt}(
                    WORMHOLE_RELAYERS[i],
                    contractAddress[chainId][bytes("RECEIVER_GAC")]
                )
            );
            contractAddress[chainId][bytes("WORMHOLE_RECEIVER_ADAPTER")] = receiverAdapter;
            _receiverAdapters[i] = receiverAdapter;

            vm.stopBroadcast();
            unchecked {
                ++i;
            }
        }

        for (uint256 j; j < len; ++j) {
            uint256 chainId = ALL_CHAINS[j];
            /// @dev sets some configs to sender adapter (ETH_CHAIN_ADAPTER)
            vm.selectFork(fork[chainId]);
            vm.startBroadcast(privKey);
            WormholeSenderAdapter(contractAddress[chainId][bytes("WORMHOLE_SENDER_ADAPTER")]).updateReceiverAdapter(
                ALL_CHAINS, _receiverAdapters
            );

            WormholeSenderAdapter(contractAddress[chainId][bytes("WORMHOLE_SENDER_ADAPTER")]).setChainIdMap(
                ALL_CHAINS, WORMHOLE_CHAIN_IDS
            );
            vm.stopBroadcast();
        }
    }

    /// @dev deploys the axelar adapters to all configured chains
    function _deployAxelarAdapters() internal {
        uint256 len = ALL_CHAINS.length;

        /// @notice deploy receiver adapters to all DST_CHAINS
        address[] memory _receiverAdapters = new address[](len);

        for (uint256 i; i < len;) {
            uint256 chainId = ALL_CHAINS[i];
            vm.selectFork(fork[chainId]);
            vm.startBroadcast(privKey);

            contractAddress[chainId][bytes("AXELAR_SENDER_ADAPTER")] = address(
                new AxelarSenderAdapter{salt: _salt}(
                    contractAddress[chainId][bytes("SENDER_GAC")]
                )
            );

            AxelarSenderAdapter(contractAddress[chainId][bytes("AXELAR_SENDER_ADAPTER")]).setAxelarConfig(
                AXELAR_GAS_SERVICES[i], AXELAR_GATEWAYS[i]
            );

            address receiverAdapter = address(
                new AxelarReceiverAdapter{salt: _salt}(
                    contractAddress[chainId][bytes("RECEIVER_GAC")]
                )
            );
            AxelarReceiverAdapter(receiverAdapter).setAxelarConfig(AXELAR_GATEWAYS[i]);

            contractAddress[chainId][bytes("AXELAR_RECEIVER_ADAPTER")] = receiverAdapter;
            _receiverAdapters[i] = receiverAdapter;

            vm.stopBroadcast();
            unchecked {
                ++i;
            }
        }

        for (uint256 j; j < len;) {
            uint256 chainId = ALL_CHAINS[j];
            vm.selectFork(fork[chainId]);
            vm.startBroadcast(privKey);

            AxelarSenderAdapter(contractAddress[chainId][bytes("AXELAR_SENDER_ADAPTER")]).updateReceiverAdapter(
                ALL_CHAINS, _receiverAdapters
            );

            AxelarSenderAdapter(contractAddress[chainId][bytes("AXELAR_SENDER_ADAPTER")]).setChainIdMap(
                ALL_CHAINS, AXELAR_CHAIN_IDS
            );
            vm.stopBroadcast();

            unchecked {
                ++j;
            }
        }
    }

    /// @dev deploys the mma sender and receiver adapters to all configured chains
    function _deployCoreContracts() internal {
        for (uint256 i; i < ALL_CHAINS.length; i++) {
            uint256 chainId = ALL_CHAINS[i];

            vm.selectFork(fork[chainId]);
            vm.startBroadcast(privKey);

            address mmaSender = address(
                new MultiBridgeMessageSender{salt: _salt}(
                    contractAddress[chainId][bytes("SENDER_GAC")]
                )
            );

            address[] memory _receiverAdapters = new address[](2);
            _receiverAdapters[0] = contractAddress[chainId][bytes("WORMHOLE_RECEIVER_ADAPTER")];
            _receiverAdapters[1] = contractAddress[chainId][bytes("AXELAR_RECEIVER_ADAPTER")];

            address mmaReceiver = address(
                new MultiBridgeMessageReceiver{salt: _salt}(
                    contractAddress[chainId][bytes("RECEIVER_GAC")],
                    _receiverAdapters,
                    2
                )
            );

            contractAddress[chainId][bytes("MMA_SENDER")] = mmaSender;
            contractAddress[chainId][bytes("MMA_RECEIVER")] = mmaReceiver;
            contractAddress[chainId][bytes("XERC20")] = address(
                new xERC20{salt: _salt}(
                    "MMA_ERC20",
                    "MMA20",
                    vm.addr(privKey),
                    mmaSender,
                    mmaReceiver
                )
            );
            vm.stopBroadcast();
        }
    }

    /// @dev setup core contracts
    function _setupCoreContracts() internal {
        /// setup mma receiver adapters
        for (uint256 i; i < ALL_CHAINS.length;) {
            uint256 chainId = ALL_CHAINS[i];

            vm.selectFork(fork[chainId]);
            vm.startBroadcast(privKey);

            address[] memory _senderAdapters = _sortTwoAdapters(
                contractAddress[chainId][bytes("AXELAR_SENDER_ADAPTER")],
                contractAddress[chainId][bytes("WORMHOLE_SENDER_ADAPTER")]
            );

            MultiBridgeMessageSender(contractAddress[chainId][bytes("MMA_SENDER")]).addSenderAdapters(_senderAdapters);

            MessageSenderGAC senderGAC = MessageSenderGAC(contractAddress[chainId][bytes("SENDER_GAC")]);
            senderGAC.setMultiBridgeMessageSender(contractAddress[chainId][bytes("MMA_SENDER")]);
            senderGAC.setAuthorisedCaller(contractAddress[chainId][bytes("XERC20")]);
            senderGAC.setGlobalMsgDeliveryGasLimit(300000);

            MultiBridgeMessageReceiver dstMMReceiver =
                MultiBridgeMessageReceiver(contractAddress[chainId][bytes("MMA_RECEIVER")]);
            dstMMReceiver.updateXERC20(contractAddress[chainId]["XERC20"]);

            MessageReceiverGAC receiverGAC = MessageReceiverGAC(contractAddress[chainId][bytes("RECEIVER_GAC")]);
            receiverGAC.setMultiBridgeMessageReceiver(address(dstMMReceiver));

            for (uint256 j; j < ALL_CHAINS.length; j++) {
                if (ALL_CHAINS[j] != chainId) {
                    senderGAC.setRemoteMultiBridgeMessageReceiver(
                        ALL_CHAINS[j], contractAddress[ALL_CHAINS[i]][bytes("MMA_RECEIVER")]
                    );
                }
            }

            vm.stopBroadcast();
            unchecked {
                ++i;
            }
        }
    }

    /// @dev setup adapter contracts
    function _setupAdapters() internal {
        for (uint256 i; i < ALL_CHAINS.length;) {
            uint256 chainId = ALL_CHAINS[i];
            vm.selectFork(fork[chainId]);
            vm.startBroadcast(privKey);

            WormholeReceiverAdapter(contractAddress[chainId]["WORMHOLE_RECEIVER_ADAPTER"]).updateSenderAdapter(
                contractAddress[chainId]["WORMHOLE_SENDER_ADAPTER"]
            );

            AxelarReceiverAdapter(contractAddress[chainId]["AXELAR_RECEIVER_ADAPTER"]).updateSenderAdapter(
                contractAddress[chainId]["AXELAR_SENDER_ADAPTER"]
            );

            vm.stopBroadcast();
            unchecked {
                ++i;
            }
        }
    }

    // @dev sorts two adapters
    function _sortTwoAdapters(address adapterA, address adapterB) internal pure returns (address[] memory adapters) {
        adapters = new address[](2);
        if (adapterA < adapterB) {
            adapters[0] = adapterA;
            adapters[1] = adapterB;
        } else {
            adapters[0] = adapterB;
            adapters[1] = adapterA;
        }
    }
}
