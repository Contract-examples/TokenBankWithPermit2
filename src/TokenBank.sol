// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract TokenBank {
    // token
    IERC20 public token;

    // user => balance
    mapping(address => uint256) public balances;

    // error
    error DepositTooLow();
    error InsufficientBalance();
    error TransferFailedForDeposit();
    error TransferFailedForWithdraw();

    // event
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor(address _token) {
        token = IERC20(_token);
    }

    function deposit(uint256 amount) public {
        // if amount is 0, revert
        if (amount == 0) {
            revert DepositTooLow();
        }

        // transfer token from user to contract
        if (!token.transferFrom(msg.sender, address(this), amount)) {
            revert TransferFailedForDeposit();
        }

        // update balance
        balances[msg.sender] += amount;

        // emit event
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        // if amount > balance, revert
        if (amount > balances[msg.sender]) {
            revert InsufficientBalance();
        }

        // update balance
        balances[msg.sender] -= amount;

        // emit event
        emit Withdraw(msg.sender, amount);

        // transfer token from contract to user
        if (!token.transfer(msg.sender, amount)) {
            revert TransferFailedForWithdraw();
        }
    }

    // Query contract balance
    function getBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    // Query specific depositor's deposit amount
    function getDepositAmount(address depositor) public view returns (uint256) {
        return balances[depositor];
    }
}
