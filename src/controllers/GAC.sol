// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.20;

import "openzeppelin-contracts/contracts/access/Ownable.sol";

/// local imports
import {IGAC} from "../interfaces/controllers/IGAC.sol";
import {Error} from "../libraries/Error.sol";

/// @dev is the global access control contract for bridge adapters
contract GAC is IGAC, Ownable {
    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address _owner) Ownable(_owner) {}

    /*///////////////////////////////////////////////////////////////
                        EXTERNAL VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IGAC
    function isGlobalOwner(address _caller) external view override returns (bool) {
        return _caller == owner();
    }

    /// @inheritdoc IGAC
    function getGlobalOwner() external view override returns (address _owner) {
        _owner = owner();
    }
}
