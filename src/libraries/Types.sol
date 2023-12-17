// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.20;

struct AdapterPayload {
    bytes32 msgId;
    address senderAdapter;
    address receiverAdapter;
    address to;
    bytes data;
}
