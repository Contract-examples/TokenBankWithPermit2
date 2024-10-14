// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/TokenBank.sol";

contract TokenBankSepoliaScript is Script {
    function setUp() public { }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("SEPOLIA_WALLET_PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        address tokenAddress = vm.envAddress("TOKEN_CONTRACT_ADDRESS");
        address bankAddress = vm.envAddress("BANK_CONTRACT_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        TokenBank bank = TokenBank(bankAddress);

        console2.log("Using Bank at:", address(bank));
        console2.log("Deployed by:", deployerAddress);
        console2.log("Using token at:", tokenAddress);

        uint256 balance = bank.getBalance();
        console2.log("Bank balance:", balance);

        vm.stopBroadcast();
    }
}
