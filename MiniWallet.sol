// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract MiniWallet is ReentrancyGuard {
    struct UserInfo {
        uint balance;
        uint lastDepositTime;
        int[] pastTransactions;
    }

    mapping(address => UserInfo) public users;

    event Deposit(address indexed user, uint amount, uint timestamp);
    event Withdraw(address indexed user, uint amount, uint timestamp);

    constructor() {}

    function deposit() external payable nonReentrant {
        require(msg.value > 0, "Amount must be greater than 0");

        UserInfo storage user = users[msg.sender];
        user.balance += msg.value;
        user.lastDepositTime = block.timestamp;
        user.pastTransactions.push(int(msg.value));

        emit Deposit(msg.sender, msg.value, block.timestamp);
    }

    function withdraw(uint amount) external nonReentrant {
        UserInfo storage user = users[msg.sender];
        require(user.balance >= amount, "Insufficient balance");

        user.balance -= amount;

        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Failed to send Ether");

        user.pastTransactions.push(-int(amount)); 

        emit Withdraw(msg.sender, amount, block.timestamp);
    }

    function getMyInfo() external view returns (UserInfo memory) {
        return users[msg.sender];
    }
}
