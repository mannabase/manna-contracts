// Be name Khoda

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.4/contracts/access/Ownable.sol";


interface IERC20 {
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}


interface IBrightID {
    event Verified(address indexed addr);
    function verifications(address addr) external view returns (uint);
    function history(address addr) external view returns (address);
}


contract ClaimManna is Ownable {
    IBrightID public brightid;
    IERC20 public mannaToken;
    mapping(address => uint256) public lastClaim;
    mapping(address => uint256) private previous;
    uint256 public maxClaimable = 7;
    uint256 public timePeriod = 24 * 60 * 60;
    uint256 public claimCount = 0;

    constructor(address brightidAddr, address mannaAddr) {
        brightid = IBrightID(brightidAddr);
        mannaToken = IERC20(mannaAddr);
    }

    function setBrightID(address addr) external onlyOwner {
        brightid = IBrightID(addr);
    }

    function setMannaToken(address addr) external onlyOwner {
        mannaToken = IERC20(addr);
    }

    function setMaxClaimable(uint256 maxClaimable_) external onlyOwner {
        maxClaimable = maxClaimable_;
    }

    function setTimePriod(uint256 timePeriod_) external onlyOwner {
        timePeriod = timePeriod_;
    }

    function approveManna(address spender, uint256 amount) external onlyOwner {
        mannaToken.approve(spender, amount);
    }

    function isVerified(address addr) external view returns (bool) {
        return brightid.verifications(addr) > 0;
    }

    function isRegistered(address addr) external view returns (bool) {
        return lastClaim[addr] != 0;
    }

    function toClaim(address addr) external view returns (uint256) {
        if (lastClaim[addr] == 0) {
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
    }

    function claim() external {
        require (maxClaimable != 0, "contract is stopped");
        require (brightid.verifications(msg.sender) > 0, "address is not verified");
        require (lastClaim[msg.sender] != 0, "not registered yet");
        uint256 time = block.timestamp;
        address addr = msg.sender;
        uint256 thisCount = ++claimCount;
        while (addr != address(0) && previous[addr] != thisCount) {
            require (lastClaim[addr] != 0 && (time - lastClaim[addr]) > timePeriod, "no manna to claim");
            previous[addr] = thisCount;
            addr = brightid.history(addr);
        }
        uint256 amount = (time - lastClaim[msg.sender]) / timePeriod;
        if (amount > maxClaimable) {
            amount = maxClaimable;
        }
        mannaToken.transfer(msg.sender, amount * 10 ** mannaToken.decimals());
        addr = msg.sender;
        while (addr != address(0) && previous[addr] == thisCount) {
            lastClaim[addr] = time;
            previous[addr] = 0;
            addr = brightid.history(addr);
        }
    }
}

// Dar panah Khoda
