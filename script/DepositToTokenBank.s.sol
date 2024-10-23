// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/TokenBank.sol";
import "../src/SimpleToken2612.sol";

contract DepositToTokenBankScript is Script {
    function setUp() public { }

    function run() public {
        uint256 userPrivateKey = vm.envUint("RECIPIENT_PRIVATE_KEY");
        address userAddress = vm.addr(userPrivateKey);
        address tokenAddress = vm.envAddress("TOKEN_CONTRACT_ADDRESS");
        address bankAddress = vm.envAddress("BANK_CONTRACT_ADDRESS");

        vm.startBroadcast(userPrivateKey);

        SimpleToken2612 token = SimpleToken2612(tokenAddress);
        TokenBank bank = TokenBank(bankAddress);

        uint256 amountToDeposit = 10 * 10 ** 18; // deposit 10 tokens

        // approve TokenBank to use tokens
        token.approve(bankAddress, amountToDeposit);
        console2.log("Approved TokenBank to use tokens");

        // deposit tokens to TokenBank
        bank.deposit(amountToDeposit);
        console2.log("Deposited tokens to TokenBank");

        // check balance after deposit
        uint256 balance = bank.getDepositAmount(userAddress);
        console2.log("User balance in TokenBank:", balance);

        // check bank balance
        uint256 bankBalance = bank.getBalance();
        console2.log("Bank balance:", bankBalance);

        vm.stopBroadcast();
    }
}
