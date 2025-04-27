// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract SourceWallet is ReentrancyGuard {

    struct User {
        uint balance;
        uint lastWithdrawTime;
        uint withdrawnToday;
    }

    mapping(address => User) public users;
    mapping(address => uint) public lastWithdrawDay;

    uint public dailyLimit = 1 ether;
    uint public lockTime = 1 days;

    address public owner;

    bool private locked;

    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable {
        require(msg.value > 0, "Must send ETH");

        users[msg.sender].balance += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint amount) external nonReentrant {
        User storage user = users[msg.sender];

        require(amount > 0, "Cannot withdraw 0");
        require(user.balance >= amount, "Insufficient balance");

        if (lastWithdrawDay[msg.sender] < block.timestamp / 1 days) {
            user.withdrawnToday = 0;
            lastWithdrawDay[msg.sender] = block.timestamp / 1 days;
        }
        require(user.withdrawnToday + amount <= dailyLimit, "Daily limit exceeded");
        require(block.timestamp >= user.lastWithdrawTime + lockTime, "Funds are locked");

        user.balance -= amount;
        user.withdrawnToday += amount;
        user.lastWithdrawTime = block.timestamp;

        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Withdraw failed");

        emit Withdraw(msg.sender, amount);
    }

    function getBalance() external view returns (uint) {
        return users[msg.sender].balance;
    }

    function setDailyLimit(uint _limit) external onlyOwner {
        dailyLimit = _limit;
    }

    function setLockTime(uint _time) external onlyOwner {
        lockTime = _time;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        owner = newOwner;
    }
}
