// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract MultiSigWallet is ReentrancyGuard {
    address[] public owners;
    uint public requiredConfirmations;

    mapping(address => bool) public isOwner;
    mapping(uint => Transaction) public transactions;
    uint public transactionCount;

    enum TransactionStatus { Pending, Approved, Executed }

    struct Transaction {
        address to;
        uint value;
        bool executed;
        mapping(address => bool) isConfirmed;
        uint confirmationCount;
    }

    event Deposit(address indexed sender, uint amount);
    event TransactionCreated(uint indexed transactionId, address indexed to, uint value);
    event TransactionConfirmed(uint indexed transactionId, address indexed owner);
    event TransactionExecuted(uint indexed transactionId);

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }

    modifier transactionExists(uint _transactionId) {
        require(_transactionId < transactionCount, "Transaction does not exist");
        _;
    }

    modifier notExecuted(uint _transactionId) {
        require(!transactions[_transactionId].executed, "Transaction already executed");
        _;
    }

    modifier enoughConfirmations(uint _transactionId) {
        require(transactions[_transactionId].confirmationCount >= requiredConfirmations, "Not enough confirmations");
        _;
    }

    modifier nonReentrant() {
        _nonReentrant();
        _;
    }

    constructor(address[] memory _owners, uint _requiredConfirmations) {
        require(_owners.length > 0, "Owners required");
        require(_requiredConfirmations > 0 && _requiredConfirmations <= _owners.length, "Invalid number of confirmations");

        for (uint i = 0; i < _owners.length; i++) {
            isOwner[_owners[i]] = true;
            owners.push(_owners[i]);
        }

        requiredConfirmations = _requiredConfirmations;
    }

    function deposit() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function createTransaction(address _to, uint _value) external onlyOwner {
        uint transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            to: _to,
            value: _value,
            executed: false,
            confirmationCount: 0
        });
        transactionCount++;

        emit TransactionCreated(transactionId, _to, _value);
    }

    function confirmTransaction(uint _transactionId) external onlyOwner transactionExists(_transactionId) notExecuted(_transactionId) {
        require(!transactions[_transactionId].isConfirmed[msg.sender], "Transaction already confirmed by you");

        transactions[_transactionId].isConfirmed[msg.sender] = true;
        transactions[_transactionId].confirmationCount++;

        emit TransactionConfirmed(_transactionId, msg.sender);
    }

    function executeTransaction(uint _transactionId) external onlyOwner transactionExists(_transactionId) enoughConfirmations(_transactionId) notExecuted(_transactionId) nonReentrant {
        Transaction storage txn = transactions[_transactionId];

        txn.executed = true;
        (bool success, ) = txn.to.call{value: txn.value}("");
        require(success, "Transaction execution failed");

        emit TransactionExecuted(_transactionId);
    }

    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() external view returns (uint) {
        return transactionCount;
    }
}
