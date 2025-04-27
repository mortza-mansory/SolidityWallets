// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// It allows the owner to receive, store, and withdraw ETH securely.
// It uses "Ownable" to control who can make changes, 
// and "ReentrancyGuard" to prevent reentrancy attacks.
// It includes basic features like deposit, withdraw, and owner change.

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SmartWallet is Ownable, ReentrancyGuard {
    event Deposit(address indexed sender, uint amount);
    event Withdraw(address indexed receiver, uint amount);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    constructor(address initialOwner) {
        require(initialOwner != address(0), "Owner address cannot be zero");
        transferOwnership(initialOwner);
    }

    receive() external payable {
        require(msg.value > 0, "Cannot send 0 ETH");
        emit Deposit(msg.sender, msg.value);
    }

    function deposit() external payable nonReentrant {
        require(msg.value > 0, "Must send ETH");
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(address payable to, uint amount) external onlyOwner nonReentrant {
        require(to != address(0), "Cannot withdraw to zero address");
        require(address(this).balance >= amount, "Insufficient balance");
        
        (bool sent, ) = to.call{value: amount}("");
        require(sent, "Failed to send Ether");

        emit Withdraw(to, amount);
    }

    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        emit OwnerChanged(owner(), newOwner);
        transferOwnership(newOwner);
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }
}
