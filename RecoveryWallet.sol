// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


/**
 * The owner can deposit and withdraw Ether.
 * If the owner loses access, a group of trusted guardians can vote to recover the ownership.
 * 
 * Main Features:
 * - Deposit and withdraw Ether by the owner.
 * - A list of guardians can propose a new owner if the original owner is lost.
 * - If enough guardians (threshold) approve the same new owner, the ownership is transferred.
 * - Protection against reentrancy attacks using OpenZeppelin's ReentrancyGuard.
 * 
 * How Social Recovery Works:
 * - Guardians propose a new owner address.
 * - When the number of votes for the same address reaches the threshold, ownership automatically changes.
 * - All previous recovery votes reset after a successful recovery.
 */


contract RecoveryWallet is Ownable, ReentrancyGuard {
    address[] public guardians;
    mapping(address => bool) public isGuardian;
    mapping(address => address) public recoveryVotes;

    event Deposit(address indexed sender, uint amount);
    event Withdraw(address indexed receiver, uint amount);
    event RecoveryProposed(address indexed guardian, address indexed newOwner);
    event OwnerRecovered(address indexed newOwner);

    uint public recoveryThreshold;

    constructor(address initialOwner, address[] memory _guardians, uint _recoveryThreshold) {
        require(initialOwner != address(0), "Owner cannot be zero");
        require(_guardians.length >= _recoveryThreshold, "Not enough guardians");

        transferOwnership(initialOwner);
        guardians = _guardians;
        recoveryThreshold = _recoveryThreshold;

        for (uint i = 0; i < _guardians.length; i++) {
            isGuardian[_guardians[i]] = true;
        }
    }

    receive() external payable {
        require(msg.value > 0, "Send ETH");
        emit Deposit(msg.sender, msg.value);
    }

    function deposit() external payable nonReentrant {
        require(msg.value > 0, "Must send ETH");
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(address payable to, uint amount) external onlyOwner nonReentrant {
        require(address(this).balance >= amount, "Not enough balance");
        require(to != address(0), "Zero address not allowed");

        (bool sent, ) = to.call{value: amount}("");
        require(sent, "Failed to send Ether");

        emit Withdraw(to, amount);
    }

    function proposeRecovery(address newOwner) external {
        require(isGuardian[msg.sender], "Not a guardian");
        require(newOwner != address(0), "New owner cannot be zero address");

        recoveryVotes[msg.sender] = newOwner;

        emit RecoveryProposed(msg.sender, newOwner);

        uint count = 0;
        for (uint i = 0; i < guardians.length; i++) {
            if (recoveryVotes[guardians[i]] == newOwner) {
                count++;
            }
        }

        if (count >= recoveryThreshold) {
            _recover(newOwner);
        }
    }

    function _recover(address newOwner) internal {
        transferOwnership(newOwner);

        for (uint i = 0; i < guardians.length; i++) {
            recoveryVotes[guardians[i]] = address(0);
        }

        emit OwnerRecovered(newOwner);
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }
}
