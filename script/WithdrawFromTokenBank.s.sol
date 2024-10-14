// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/SimpleToken.sol";
import "../src/TokenBank.sol";

contract WithdrawFromTokenBankScript is Script {
    function setUp() public { }

    function run() public {
        uint256 userPrivateKey = vm.envUint("RECIPIENT_PRIVATE_KEY");
        address userAddress = vm.addr(userPrivateKey);
        address tokenAddress = vm.envAddress("TOKEN_CONTRACT_ADDRESS");
        address bankAddress = vm.envAddress("BANK_CONTRACT_ADDRESS");

        vm.startBroadcast(userPrivateKey);

        SimpleToken token = SimpleToken(tokenAddress);
        TokenBank bank = TokenBank(bankAddress);

        uint256 amountToWithdraw = 1 * 10 ** 18; // withdraw 1 tokens

        // TokenBank has been approved by default for withdraw
        // token.approve(bankAddress, amountToWithdraw);
        // console2.log("Approved TokenBank to use tokens");

        // withdraw tokens from TokenBank
        bank.withdraw(amountToWithdraw);
        console2.log("Withdrawn tokens from TokenBank");

        // check balance after deposit
        uint256 balance = bank.getDepositAmount(userAddress);
        console2.log("User balance in TokenBank:", balance);

        // check bank balance
        uint256 bankBalance = bank.getBalance();
        console2.log("Bank balance:", bankBalance);

        vm.stopBroadcast();
    }
}
