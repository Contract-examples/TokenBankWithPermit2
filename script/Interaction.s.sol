// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@permit2/interfaces/IPermit2.sol";
import "@permit2/interfaces/ISignatureTransfer.sol";
import "../src/TokenBank.sol";
import "../src/SimpleToken2612.sol";

contract InteractionScript is Script {
    // Contract addresses
    address constant BANK_ADDRESS = 0xdB3eF3cB3079C93A276A2B4B69087b8801727f64;
    address constant PERMIT2_ADDRESS = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    address payable TOKEN_ADDRESS = payable(0xe4Cec63058807C50C95CEF99b0Ab5A9831610386);

    // Contract interfaces
    TokenBank bank = TokenBank(payable(BANK_ADDRESS));
    SimpleToken2612 token = SimpleToken2612(TOKEN_ADDRESS);
    IPermit2 permit2 = IPermit2(PERMIT2_ADDRESS);

    function run() external {
        // TODO: encrypt your private key
        uint256 privateKey = vm.envUint("SEPOLIA_WALLET_PRIVATE_KEY");
        address user = vm.addr(privateKey);

        // Parameters for depositWithPermit2
        uint256 depositAmount = 1 * 10 ** 18;

        // Get nonce
        uint256 wordPos = 0;
        uint256 bitmap = permit2.nonceBitmap(user, wordPos);
        uint256 nonce = _findNextNonce(bitmap, wordPos);
        console2.log("nonce:", nonce);

        // Set deadline
        uint256 deadline = block.timestamp + 1 hours;

        // Create permit message
        ISignatureTransfer.PermitTransferFrom memory permit = ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({ token: TOKEN_ADDRESS, amount: depositAmount }),
            nonce: nonce,
            deadline: deadline
        });

        // Generate signature
        bytes32 digest = _getPermitTransferFromDigest(permit, BANK_ADDRESS, PERMIT2_ADDRESS);
        console2.log("digest: %s", Strings.toHexString(uint256(digest)));

        // Sign the digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        console2.log("v: %s", Strings.toHexString(uint256(v)));
        console2.log("r: %s", Strings.toHexString(uint256(r)));
        console2.log("s: %s", Strings.toHexString(uint256(s)));

        // Encode the signature
        bytes memory signature = abi.encodePacked(r, s, v);
        console2.log("signature:");
        console2.logBytes(signature);

        // Log initial states
        console2.log("User address:", user);
        console2.log("Initial token balance:", token.balanceOf(user));
        console2.log("Initial bank balance:", bank.balances(user));
        console2.log("Permit2 allowance:", token.allowance(user, PERMIT2_ADDRESS));

        // Start broadcasting transactions
        vm.startBroadcast(privateKey);

        // Approve Permit2 if needed
        if (token.allowance(user, PERMIT2_ADDRESS) < depositAmount) {
            token.approve(PERMIT2_ADDRESS, type(uint256).max);
            console2.log("Approved Permit2");
        }

        // Execute deposit with permit2
        bank.depositWithPermit2(depositAmount, nonce, deadline, signature);

        vm.stopBroadcast();

        // Log final states
        console2.log("Final token balance:", token.balanceOf(user));
        console2.log("Final bank balance:", bank.balances(user));
        console2.log("Interaction completed!");
    }

    function _getPermitTransferFromDigest(
        ISignatureTransfer.PermitTransferFrom memory permit,
        address spender,
        address permit2Address
    )
        internal
        view
        returns (bytes32)
    {
        bytes32 DOMAIN_SEPARATOR = IPermit2(permit2Address).DOMAIN_SEPARATOR();

        bytes32 typeHash = keccak256(
            "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
        );

        bytes32 tokenPermissionsHash = keccak256(
            abi.encode(
                keccak256("TokenPermissions(address token,uint256 amount)"),
                permit.permitted.token,
                permit.permitted.amount
            )
        );

        bytes32 structHash =
            keccak256(abi.encode(typeHash, tokenPermissionsHash, spender, permit.nonce, permit.deadline));

        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
    }

    // find the next available nonce
    function _findNextNonce(uint256 bitmap, uint256 wordPos) internal pure returns (uint256) {
        // find the first unused bit in the current bitmap
        uint256 bit;
        for (bit = 0; bit < 256; bit++) {
            if ((bitmap & (1 << bit)) == 0) {
                break;
            }
        }

        // calculate the full nonce
        // nonce = (wordPos << 8) | bit
        return (wordPos << 8) | bit;
    }
}
