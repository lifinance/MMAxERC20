// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.20;

import {Vm} from "forge-std/Test.sol";

/// library imports
import {Setup} from "./Setup.t.sol";
import "forge-std/console.sol";
import "wormhole-solidity-sdk/interfaces/IWormholeRelayer.sol";

/// local imports
import {xERC20} from "src/token/xERC20.sol";
import {MultiBridgeMessageReceiver} from "src/MultiBridgeMessageReceiver.sol";
import "src/libraries/Message.sol";

contract SimpleTransferTest is Setup {
    function setUp() public override {
        super.setUp();
    }

    function test_xChainTransfer() external {
        _srcToDst();
        _dstToSrc();
    }

    function _srcToDst() internal {
        vm.selectFork(fork[SRC_CHAIN_ID]);
        vm.startPrank(owner);

        deal(owner, 2 ether);
        uint256[] memory _fees = new uint256[](2);
        _fees[0] = 1 ether;

        (uint256 wormholeFee, ) = IWormholeRelayer(ETH_RELAYER)
            .quoteEVMDeliveryPrice(5, 0, 300000);
        _fees[1] = wormholeFee;

        vm.recordLogs();
        uint256 expiration = block.timestamp + 29 days;
        xERC20(contractAddress[SRC_CHAIN_ID][bytes("XERC20")]).xChainTransfer{
            value: 1 ether + wormholeFee
        }(DST_CHAIN_ID, _fees, owner, 1e18);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        vm.stopPrank();

        vm.recordLogs();
        _simulatePayloadDelivery(SRC_CHAIN_ID, DST_CHAIN_ID, logs);
        bytes32 msgId = _getMsgId(vm.getRecordedLogs());

        vm.selectFork(fork[DST_CHAIN_ID]);
        vm.recordLogs();

        /// execute the received message
        MultiBridgeMessageReceiver(
            contractAddress[DST_CHAIN_ID][bytes("MMA_RECEIVER")]
        ).executeMessage(
                msgId,
                MessageLibrary.MessageExecutionParams({
                    target: contractAddress[SRC_CHAIN_ID][bytes("XERC20")],
                    callData: bytes(""),
                    value: 1e18,
                    nonce: 1,
                    expiration: expiration
                })
            );
    }

    function _dstToSrc() internal {
        vm.selectFork(fork[DST_CHAIN_ID]);
        vm.startPrank(owner);

        deal(owner, 1000 ether);
        uint256[] memory _fees = new uint256[](2);
        _fees[0] = 1 ether;

        (uint256 wormholeFee, ) = IWormholeRelayer(POLYGON_RELAYER)
            .quoteEVMDeliveryPrice(2, 0, 300000);
        _fees[1] = wormholeFee;

        vm.recordLogs();
        uint256 expiration = block.timestamp + 29 days;
        xERC20(contractAddress[DST_CHAIN_ID][bytes("XERC20")]).xChainTransfer{
            value: 1 ether + wormholeFee
        }(SRC_CHAIN_ID, _fees, owner, 1e18);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        vm.stopPrank();

        vm.recordLogs();
        _simulatePayloadDelivery(DST_CHAIN_ID, SRC_CHAIN_ID, logs);
        bytes32 msgId = _getMsgId(vm.getRecordedLogs());

        vm.selectFork(fork[SRC_CHAIN_ID]);

        /// execute the received message
        MultiBridgeMessageReceiver(
            contractAddress[SRC_CHAIN_ID][bytes("MMA_RECEIVER")]
        ).executeMessage(
                msgId,
                MessageLibrary.MessageExecutionParams({
                    target: contractAddress[DST_CHAIN_ID][bytes("XERC20")],
                    callData: bytes(""),
                    value: 1e18,
                    nonce: 1,
                    expiration: expiration
                })
            );
    }
}
