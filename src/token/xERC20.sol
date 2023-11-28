pragma solidity ^0.8.13;

/// library imports
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// local imports
import {IXERC20} from "src/interfaces/EIP7281/IXERC20.sol";

interface IMultiMessageSender {
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
    IMultiMessageSender public mmaSender;
    address public mmaReceiver;

    modifier onlyMultiMessageReceiver() {
        require(msg.sender == address(mmaReceiver), "xERC20: invalid caller");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _initialOwner,
        address _mmaSender,
        address _mmaReceiver
    ) ERC20(_name, _symbol) {
        mmaSender = IMultiMessageSender(_mmaSender);
        mmaReceiver = _mmaReceiver;

        // @dev mints 1 million tokens to initial owner
        _mint(_initialOwner, 1e24);
    }

    function xChainTransfer(uint256 _dstChainId, uint256[] calldata _fees, address _receiver, uint256 _amount)
        external
        payable
    {
        _burn(msg.sender, _amount);

        // assume CREATE2
        // assume msg has 29 day expiration
        // assume msg.sender as refund address
        mmaSender.remoteCall{value: msg.value}(
            _dstChainId, address(this), bytes(""), _amount, 29 days, msg.sender, _fees, 2, new address[](0)
        );
    }

    function setLockbox(address _lockbox) external override {
        // no use case for now
        revert();
    }

    function setLimits(address _bridge, uint256 _mintingLimit, uint256 _burningLimit) external override {
        // no use case for now
        revert();
    }

    function mint(address _user, uint256 _amount) external override onlyMultiMessageReceiver {
        _mint(_user, _amount);
    }

    function burn(address _user, uint256 _amount) external override {
        // no use case for now
        revert();
    }

    function mintingMaxLimitOf(address _bridge) external view override returns (uint256 limits_) {
        if (_bridge != mmaReceiver) return 0;
        return type(uint256).max;
    }

    function burningMaxLimitOf(address _bridge) external view override returns (uint256 _limit) {
        return 0;
    }

    function mintingCurrentLimitOf(address _bridge) external view override returns (uint256 _limit) {
        if (_bridge != mmaReceiver) return 0;
        return type(uint256).max;
    }

    function burningCurrentLimitOf(address _bridge) external view override returns (uint256 _limit) {
        return 0;
    }
}
