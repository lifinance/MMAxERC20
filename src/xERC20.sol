pragma solidity ^0.8.13;

/// library imports
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// local imports
import {IXERC20} from "./interfaces/EIP7281/IXERC20.sol";

interface IBridge {
    function remoteCall(
        uint256 _dstChainId,
        address _target,
        bytes calldata _callData,
        uint256 _nativeValue,
        uint256 _expiration,
        address _refundAddress,
        uint256[] calldata _fees,
        uint256 _successThreshold,
        address[] memory _excludedAdapters
    ) external payable;
}

contract xERC20 is IXERC20, ERC20 {
    IBridge public bridge;

    modifier onlyBridge() {
        require(msg.sender == address(bridge), "xERC20: invalid caller");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _bridge
    ) ERC20(_name, _symbol) {
        bridge = IBridge(_bridge);

        /// @dev mints 1 million tokens
        _mint(msg.sender, 1e24);
    }

    function xChainTransfer(
        uint256 _dstChainId,
        uint256[] calldata _fees,
        address _receiver,
        uint256 _amount
    ) external payable {
        _burn(msg.sender, _amount);

        /// assume CREATE2
        /// assume msg has 29 day expiration
        /// assume msg.sender as refund address
        bridge.remoteCall{value: msg.value}(
            _dstChainId,
            address(this),
            bytes(""),
            _amount,
            29 days,
            msg.sender,
            _fees,
            2,
            new address[](0)
        );
    }

    function setLockbox(address _lockbox) external override {}

    function setLimits(
        address _bridge,
        uint256 _mintingLimit,
        uint256 _burningLimit
    ) external override {}

    function mint(address _user, uint256 _amount) external override onlyBridge {
        _mint(_user, _amount);
    }

    function burn(address _user, uint256 _amount) external override onlyBridge {
        _burn(_user, _amount);
    }

    function mintingMaxLimitOf(
        address _bridge
    ) external view override returns (uint256 limits_) {}

    function burningMaxLimitOf(
        address _bridge
    ) external view override returns (uint256 _limit) {}

    function mintingCurrentLimitOf(
        address _bridge
    ) external view override returns (uint256 _limit) {}

    function burningCurrentLimitOf(
        address _bridge
    ) external view override returns (uint256 _limit) {}
}
