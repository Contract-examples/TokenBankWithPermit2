// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/SimpleToken2612.sol";
import "../src/TokenBank.sol";

contract DeployScript is Script {
    // SALT
    bytes32 constant SALT = bytes32(uint256(0x0000000000000000000000000000000000000000d3bf2663da51c10215000003));

    // Permit2 contract address
    address constant PERMIT2_ADDRESS = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    // token address
    // https://sepolia.arbiscan.io/address/0xe4Cec63058807C50C95CEF99b0Ab5A9831610386
    address constant TOKEN_ADDRESS = 0xe4Cec63058807C50C95CEF99b0Ab5A9831610386;

    function run() external {
        // TODO: encrypt your private key
        uint256 deployerPrivateKey = vm.envUint("SEPOLIA_WALLET_PRIVATE_KEY");

        // start broadcast
        vm.startBroadcast(deployerPrivateKey);

        // deploy TokenBank
        TokenBank bank = new TokenBank{ salt: SALT }(
            TOKEN_ADDRESS, // token address
            PERMIT2_ADDRESS // permit2 address
        );
        // TokenBank deployed at: 0xdB3eF3cB3079C93A276A2B4B69087b8801727f64
        console2.log("TokenBank deployed at:", address(bank));

        // stop broadcast
        vm.stopBroadcast();

        // print deployment info
        console2.log("Deployment completed!");
    }
}
