// Be name Khoda

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.4/contracts/access/Ownable.sol";


interface IERC20 {
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}


interface IManna is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}


interface IBrightID {
    event Verified(address indexed addr);
    function verifications(address addr) external view returns (uint);
    function history(address addr) external view returns (address);
}


contract ClaimManna is Ownable {
    IBrightID public brightid;
    IManna public mannaToken;
    mapping(address => uint256) public lastClaim;
    uint256 public maxClaimable = 7;
    uint256 public timePeriod = 24 * 60 * 60;

    constructor(address brightidAddr, address mannaAddr) {
        brightid = IBrightID(brightidAddr);
        mannaToken = IManna(mannaAddr);
    }

    function setBrightID(address addr) external onlyOwner {
        brightid = IBrightID(addr);
    }

    function setMannaToken(address addr) external onlyOwner {
        mannaToken = IManna(addr);
    }

    function setMaxClaimable(uint256 maxClaimable_) external onlyOwner {
        maxClaimable = maxClaimable_;
    }

    function setTimePriod(uint256 timePeriod_) external onlyOwner {
        timePeriod = timePeriod_;
    }

    function approveToken(address tokenAddr, address spender, uint256 amount) external onlyOwner {
        IERC20(tokenAddr).approve(spender, amount);
    }

    function isVerified(address addr) external view returns (bool) {
        return brightid.verifications(addr) > 0;
    }

    function isRegistered(address addr) external view returns (bool) {
        return lastClaim[addr] != 0;
    }

    function toClaim(address addr) external view returns (uint256) {
        if (lastClaim[addr] == 0 || brightid.verifications(addr) == 0) {
            return 0;
        }
        uint256 amount = (block.timestamp - lastClaim[addr]) / timePeriod;
        if (amount > maxClaimable) {
            amount = maxClaimable;
        }
        return amount;
    }

    function register() external {
        require (brightid.verifications(msg.sender) > 0, "address is not verified");
        require (lastClaim[msg.sender] == 0, "already registered");
        lastClaim[msg.sender] = block.timestamp;
        lastClaim[brightid.history(msg.sender)] = 0;
    }

    function claim() external {
        require (maxClaimable != 0, "contract is stopped");
        require (brightid.verifications(msg.sender) > 0, "address is not verified");
        require (lastClaim[msg.sender] != 0, "not registered yet");
        uint256 time = block.timestamp;
        uint256 amount = (time - lastClaim[msg.sender]) / timePeriod;
        if (amount > maxClaimable) {
            amount = maxClaimable;
        }
        mannaToken.mint(msg.sender, amount * 10 ** mannaToken.decimals());
        lastClaim[msg.sender] = time;
    }
}

// Dar panah Khoda
