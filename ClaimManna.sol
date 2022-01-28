// Be name Khoda

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.4/contracts/access/Ownable.sol";

interface IERC20 {
    function decimals() external view returns (uint8);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IManna is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

interface IMannaBrightID {
    event Verified(address indexed addr);
    function isVerified(address addr) external view returns (bool);
    function verificationTime(address addr) external view returns (uint256);
}


contract ClaimManna is Ownable {
    IMannaBrightID public brightid;
    IManna public mannaToken;
    mapping(address => uint256) public lastClaim;
    uint256 public maxClaimable = 7;
    uint256 public claimPeriod = 24 * 60 * 60;
    uint256 public checkPeriod = 14 * 24 * 60 * 60;

    constructor(address brightidAddr, address mannaAddr) {
        brightid = IMannaBrightID(brightidAddr);
        mannaToken = IManna(mannaAddr);
    }

    function setBrightID(address addr) external onlyOwner {
        brightid = IMannaBrightID(addr);
    }

    function setMannaToken(address addr) external onlyOwner {
        mannaToken = IManna(addr);
    }

    function setMaxClaimable(uint256 maxClaimable_) external onlyOwner {
        maxClaimable = maxClaimable_;
    }

    function setClaimPeriod(uint256 claimPeriod_) external onlyOwner {
        claimPeriod = claimPeriod_;
    }

    function setCheckPeriod(uint256 checkPeriod_) external onlyOwner {
        checkPeriod = checkPeriod_;
    }

    function approveToken(address tokenAddr, address spender, uint256 amount) external onlyOwner {
        IERC20(tokenAddr).approve(spender, amount);
    }

    function isVerified(address addr) public view returns (bool) {
        uint256 time_sec = brightid.verificationTime(addr) / 1000;
        return (block.timestamp - time_sec) < checkPeriod;
    }

    modifier verified {
        require(isVerified(msg.sender), "ClaimManna: address is not verified");
        _;
    }

    function isRegistered(address addr) public view returns (bool) {
        return lastClaim[addr] != 0;
    }

    modifier registered {
        require(isRegistered(msg.sender), "ClaimManna: address is not registered yet");
        _;
    }

    function toClaim(address addr) external view returns (uint256) {
        if (lastClaim[addr] == 0) {
            return 0;
        }
        uint256 amount = (block.timestamp - lastClaim[addr]) / claimPeriod;
        if (amount > maxClaimable) {
            amount = maxClaimable;
        }
        return amount;
    }

    function register() external verified {
        require (lastClaim[msg.sender] == 0, "ClaimManna: already registered");
        lastClaim[msg.sender] = block.timestamp - claimPeriod;
    }

    function claim() external registered verified {
        require (maxClaimable != 0, "ClaimManna: contract is stopped");
        uint256 time = block.timestamp;
        uint256 amount = (time - lastClaim[msg.sender]) / claimPeriod;
        if (amount > maxClaimable) {
            amount = maxClaimable;
        }
        require(amount > 0, "ClaimManna: no Manna to claim for this address");
        mannaToken.mint(msg.sender, amount * 10 ** mannaToken.decimals());
        lastClaim[msg.sender] = time;
    }
}

// Dar panah Khoda
