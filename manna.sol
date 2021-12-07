// Be name Khoda

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.4/contracts/access/AccessControl.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.4/contracts/token/ERC20/ERC20.sol";

contract Manna is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor() ERC20("Manna", "MANNA") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _mint(msg.sender, 20000000000000000000000000);  // 20M
    }

    function mint(address to, uint256 amount) external {
        require(hasRole(MINTER_ROLE, msg.sender), "Manna: caller is not a minter");
        
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(hasRole(BURNER_ROLE, msg.sender), "Manna: caller is not a burner");

        uint256 currentAllowance = allowance(from, msg.sender);
        require(currentAllowance >= amount, "Manna: burn amount exceeds allowance");

        unchecked {
            _approve(from, msg.sender, currentAllowance - amount);
        }
        _burn(from, amount);
    }
}

// Dar panah Khoda
