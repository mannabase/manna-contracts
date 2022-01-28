// Be name Khoda

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.4/contracts/access/Ownable.sol";


interface IBrightID {
    event Verified(address indexed addr);
    function isVerified(address addr) external view returns (bool);
}

contract MannaBrightID is Ownable, IBrightID {
    mapping(address => bool) public verifiers;
    bytes32 public app;
    bytes32 public verificationHash;

    event VerifierAdded(address verifier);
    event VerifierRemoved(address verifier);
    event AppSet(bytes32 _app);
    event VerificationHashSet(bytes32 verificationHash);

    struct Verification {
        uint256 time;
        bool isVerified;
    }
    mapping(address => Verification) public verifications;

    /**
     * @param _verifier trusted node's verifier address
     * @param _app BrightID app used for verifying users
     * @param _verificationHash sha256 of the verification expression
     */
    constructor(address _verifier, bytes32 _app, bytes32 _verificationHash) {
        verifiers[_verifier] = true;
        app = _app;
        verificationHash = _verificationHash;
    }

    /**
     * @notice Set the app
     * @param _app BrightID app used for verifying users
     */
    function setApp(bytes32 _app) external onlyOwner {
        app = _app;
        emit AppSet(_app);
    }

    /**
     * @notice Set verification hash
     * @param _verificationHash sha256 of the verification expression
     */
    function setVerificationHash(bytes32 _verificationHash) external onlyOwner {
        verificationHash = _verificationHash;
        emit VerificationHashSet(_verificationHash);
    }

    /**
     * @notice Add verifier
     * @param _verifier trusted node's verifier address
     */
    function addVerifier(address _verifier) external onlyOwner {
        verifiers[_verifier] = true;
        emit VerifierAdded(_verifier);
    }

    /**
     * @notice Remove verifier
     * @param _verifier trusted node's verifier address
     */
    function removeVerifier(address _verifier) external onlyOwner {
        verifiers[_verifier] = false;
        emit VerifierRemoved(_verifier);
    }

    /**
     * @notice Register a user by BrightID verification
     * @param addr The address used by this user in the app
     * @param timestamp The BrightID node's verification timestamp
     * @param v Component of signature
     * @param r Component of signature
     * @param s Component of signature
     */
    function verify(
        address addr,
        uint timestamp,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 message = keccak256(abi.encodePacked(app, addr, verificationHash, timestamp));
        address signer = ecrecover(message, v, r, s);
        require(verifiers[signer], "signer is not a verifier");

        verifications[addr].time = timestamp;
        verifications[addr].isVerified = true;
        emit Verified(addr);
    }

    /**
     * @notice Check an address is verified or not
     * @param addr The context id used for verifying users
     */
    function isVerified(address addr) override external view returns (bool) {
        return verifications[addr].isVerified;
    }

    /**
     * @notice Returns an address verification time
     * @param addr The context id used for verifying users
     */
    function verificationTime(address addr) external view returns (uint256) {
        return verifications[addr].time;
    }
}

// Dar panah Khoda
