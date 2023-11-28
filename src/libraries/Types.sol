// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.20;

struct AdapterPayload {
    bytes32 msgId;
    address senderAdapterCaller;
    address receiverAdapter;
    address finalDestination;
    bytes data;
}
