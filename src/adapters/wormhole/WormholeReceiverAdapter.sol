/// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.20;

/// library imports
import "wormhole-solidity-sdk/interfaces/IWormholeReceiver.sol";

/// local imports
import "../../interfaces/adapters/IMessageReceiverAdapter.sol";
import "../../interfaces/IMultiBridgeMessageReceiver.sol";
import "../../interfaces/EIP7281/IXERC20.sol";
import "../../libraries/Error.sol";
import "../../libraries/Types.sol";
import "../../libraries/TypeCasts.sol";
import "../../libraries/Message.sol";

import "../../controllers/MessageReceiverGAC.sol";
import "../BaseReceiverAdapter.sol";

import "forge-std/console.sol";

/// @notice receiver adapter for wormhole bridge
/// @dev allows wormhole relayers to write to receiver adapter which then forwards the message to
/// the MMA receiver.
contract WormholeReceiverAdapter is BaseReceiverAdapter, IWormholeReceiver {
    string public constant name = "WORMHOLE";
    address public immutable relayer;

    /*/////////////////////////////////////////////////////////////////
                            STATE VARIABLES
    ////////////////////////////////////////////////////////////////*/

    mapping(bytes32 => bool) public isMessageExecuted;
    mapping(bytes32 => bool) public deliveryHashStatus;

    /*/////////////////////////////////////////////////////////////////
                                 MODIFIER
    ////////////////////////////////////////////////////////////////*/

    modifier onlyRelayerContract() {
        if (msg.sender != relayer) {
            revert Error.CALLER_NOT_WORMHOLE_RELAYER();
        }
        _;
    }

    /*/////////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    ////////////////////////////////////////////////////////////////*/

    /// @param _relayer is wormhole relayer.
    /// @param _receiverGAC is global access controller.
    /// note: https://docs.wormhole.com/wormhole/quick-start/cross-chain-dev/automatic-relayer
    constructor(address _relayer, address _receiverGAC) BaseReceiverAdapter(_receiverGAC) {
        if (_relayer == address(0)) {
            revert Error.ZERO_ADDRESS_INPUT();
        }

        relayer = _relayer;
    }

    /*/////////////////////////////////////////////////////////////////
                                EXTERNAL FUNCTIONS
    ////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IWormholeReceiver
    function receiveWormholeMessages(
        bytes memory _payload,
        bytes[] memory,
        bytes32 _sourceAddress,
        uint16 _sourceChainId,
        bytes32 _deliveryHash
    ) public payable override onlyRelayerContract {
        /// @dev step-1: validate the source address
        /// @notice: CREATE2 assumption
        if (TypeCasts.bytes32ToAddress(_sourceAddress) != senderAdapter) {
            revert Error.INVALID_SENDER_ADAPTER();
        }

        /// decode the cross-chain payload
        AdapterPayload memory decodedPayload = abi.decode(_payload, (AdapterPayload));
        bytes32 msgId = decodedPayload.msgId;

        /// @dev step-2: check for duplicate message
        if (isMessageExecuted[msgId] || deliveryHashStatus[_deliveryHash]) {
            revert MessageIdAlreadyExecuted(msgId);
        }

        isMessageExecuted[decodedPayload.msgId] = true;
        deliveryHashStatus[_deliveryHash] = true;

        /// @dev step-3: validate the receive adapter
        if (decodedPayload.receiverAdapter != address(this)) {
            revert Error.INVALID_RECEIVER_ADAPTER();
        }

        address mmaReceiver = receiverGAC.multiBridgeMsgReceiver();

        if (decodedPayload.to == mmaReceiver) {
            MessageLibrary.Message memory _data = abi.decode(decodedPayload.data, (MessageLibrary.Message));
            try IMultiBridgeMessageReceiver(mmaReceiver).receiveMessage(_data) {
                emit MessageIdExecuted(msgId);
            } catch (bytes memory lowLevelData) {
                revert MessageFailure(msgId, lowLevelData);
            }
        } else {
            (address user, uint256 amount) = abi.decode(decodedPayload.data, (address, uint256));
            try IXERC20(decodedPayload.to).mint(user, amount) {
                emit MessageIdExecuted(msgId);
            } catch (bytes memory lowLevelData) {
                revert MessageFailure(msgId, lowLevelData);
            }
        }
    }
}
