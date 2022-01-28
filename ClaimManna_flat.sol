// Be name Khoda

// SPDX-License-Identifier: MIT

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.4/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.4/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: ClaimManna.sol


pragma solidity ^0.8.10;


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
