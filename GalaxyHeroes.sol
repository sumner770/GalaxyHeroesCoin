// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract GalaxyHeroes is ERC20, Ownable, AccessControl {
    using SafeMath for uint256;

    uint256 constant TOTAL_SUPPLY = 700000000000000 ether;
    uint256 constant ROYALTY_BASE = 10000;      // royalty base
    uint256 public royaltyFee;                  // royalty, ex: 500 / 10000 = 5%
    address public royaltyReceiver;
    bool public enableTransfer;
    mapping(address => bool) public royaltyWhitelist;
    mapping(address => bool) public transferWhitelist;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    event Royalty(address indexed from, address indexed to, uint256 royalty);

    constructor(string memory _name, string memory _symbol, address _royaltyReceiver) ERC20(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OPERATOR_ROLE, _msgSender());
        royaltyReceiver = _royaltyReceiver;
        royaltyFee = 500;
        enableTransfer = false;
        transferWhitelist[_msgSender()] = true;
        royaltyWhitelist[_msgSender()] = true;
        _mint(_msgSender(), TOTAL_SUPPLY);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        address from = _msgSender();
        require(enableTransfer == true || transferWhitelist[from] == true || from == owner(), "Unable to transfer");
        if (royaltyWhitelist[from] == true) {
            _transfer(from, to, amount);
        } else {
            uint256 royaltyAmount = amount.mul(royaltyFee).div(ROYALTY_BASE);
            _transfer(from, royaltyReceiver, royaltyAmount);
            emit Royalty(from, to, royaltyAmount);
            _transfer(from, to, amount.sub(royaltyAmount));
        }
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        require(enableTransfer == true || transferWhitelist[from] == true || from == owner(), "Unable to transfer");
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        if (royaltyWhitelist[from] == true) {
            _transfer(from, to, amount);
        } else {
            uint256 royaltyAmount = amount.mul(royaltyFee).div(ROYALTY_BASE);
            _transfer(from, royaltyReceiver, royaltyAmount);
            emit Royalty(from, to, royaltyAmount);
            _transfer(from, to, amount.sub(royaltyAmount));
        }
        return true;
    }

    function transferWithoutFee(address to, uint256 amount) external returns (bool) {
        require(hasRole(OPERATOR_ROLE, _msgSender()), "Caller is not a role owner");
        address from = _msgSender();
        _transfer(from, to, amount);
        return true;
    }

    function transferFromWithoutFee(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        require(hasRole(OPERATOR_ROLE, _msgSender()), "Caller is not a role owner");
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    // ADMIN

    function setRoyaltyFee(uint256 _royaltyFee) external onlyOwner {
        royaltyFee = _royaltyFee;
    }

    function setRoyaltyReceiver(address _royaltyReceiver) external onlyOwner {
        royaltyReceiver = _royaltyReceiver;
    }

    function setEnableTransfer(bool _enableTransfer) external onlyOwner {
        enableTransfer = _enableTransfer;
    }

    function setRoyaltyWhitelist(address[] calldata whitelist, bool isWhitelist) external onlyOwner {
        require(whitelist.length > 0, "Whitelist must over 0");
        for (uint256 i = 0; i < whitelist.length; i++) {
            royaltyWhitelist[whitelist[i]] = isWhitelist;
        }
    }

    function setTransferWhitelist(address[] calldata whitelist, bool isWhitelist) external onlyOwner {
        require(whitelist.length > 0, "Whitelist must over 0");
        for (uint256 i = 0; i < whitelist.length; i++) {
            transferWhitelist[whitelist[i]] = isWhitelist;
        }
    }

    function addOperator(address account) external onlyOwner {
        grantRole(OPERATOR_ROLE, account);
    }

    function removeOperator(address account) external onlyOwner {
        revokeRole(OPERATOR_ROLE, account);
    }

}