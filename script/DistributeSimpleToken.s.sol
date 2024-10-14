// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/SimpleToken.sol";

contract DistributeSimpleTokenScript is Script {
    function setUp() public { }

    function run() public {
        // https://sepolia.arbiscan.io/tx/0xdb8efe967a12637d979d2ff48a3d339841469d918bb6d77eda5522445bf3f742
        uint256 deployerPrivateKey = vm.envUint("SEPOLIA_WALLET_PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        address tokenAddress = vm.envAddress("TOKEN_CONTRACT_ADDRESS");
        address recipientAddress = vm.envAddress("RECIPIENT_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        SimpleToken token = SimpleToken(tokenAddress);

        uint256 amountToDistribute = 1000 * 10 ** 18; // distribute 1000 tokens

        token.transfer(recipientAddress, amountToDistribute);
        console2.log("Distributed tokens to:", recipientAddress);
        console2.log("Amount distributed:", amountToDistribute);

        uint256 balance = token.balanceOf(recipientAddress);
        console2.log("Recipient balance after distribution:", balance);

        vm.stopBroadcast();
    }
}
