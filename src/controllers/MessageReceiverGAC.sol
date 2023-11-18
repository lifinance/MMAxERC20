// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.20;

import "./GAC.sol";
import "../interfaces/IMultiBridgeMessageReceiver.sol";

contract MessageReceiverGAC is GAC {
    event MultiBridgeMessageReceiverUpdated(address indexed oldMMR, address indexed newMMR);

    address public multiBridgeMsgReceiver;

    constructor(address _owner) GAC(_owner) {}

    function setMultiBridgeMessageReceiver(address _mmaReceiver) external onlyOwner {
        if (_mmaReceiver == address(0)) {
            revert Error.ZERO_ADDRESS_INPUT();
        }
        address oldMMR = multiBridgeMsgReceiver;
        multiBridgeMsgReceiver = _mmaReceiver;

        emit MultiBridgeMessageReceiverUpdated(oldMMR, _mmaReceiver);
    }
}
