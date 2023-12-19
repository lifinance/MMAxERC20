// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.20;

/// @title MessageStruct
/// @dev library for cross-chain message & related helper functions
library MessageLibrary {
    /// @dev Message indicates a remote call to target contract on destination chain.
    /// @param srcChainId is the id of chain where this message is sent from
    /// @param dstChainId is the id of chain where this message is sent to
    /// @param nonce is an incrementing number held by MultiBridgeMessageSender.sol to ensure msgId uniqueness
    /// @param target is the contract to be called on dst chain
    /// @param payload is the data to be sent to target
    /// @param expiration is the unix time when the message expires.
    struct Message {
        uint256 srcChainId;
        uint256 dstChainId;
        address target;
        uint256 nonce;
        bytes payload;
    }

    /// @notice encapsulates data that is relevant to a message's intended transaction execution.
    struct MessageExecutionParams {
        // target contract address on the destination chain
        address target;
        // data to pass to target by low-level call
        bytes payload;
        // nonce of the message
        uint256 nonce;
    }

    /// @notice computes the message id (32 byte hash of the encoded message parameters)
    /// @param _message is the cross-chain message
    function computeMsgId(Message memory _message) internal pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                _message.srcChainId, _message.dstChainId, _message.nonce, _message.target, _message.payload
            )
        );
    }

    function extractExecutionParams(Message memory _message) internal pure returns (MessageExecutionParams memory) {
        return MessageExecutionParams({target: _message.target, payload: _message.payload, nonce: _message.nonce});
    }

    function computeExecutionParamsHash(MessageExecutionParams memory _params) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_params.target, _params.payload, _params.nonce));
    }

    function computeExecutionParamsHash(Message memory _message) internal pure returns (bytes32) {
        return computeExecutionParamsHash(extractExecutionParams(_message));
    }
}
