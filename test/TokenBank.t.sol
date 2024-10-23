// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../src/TokenBank.sol";
import "../src/SimpleToken2612.sol";

contract TokenBankTest is Test {
    TokenBank public bank;
    SimpleToken2612 public token;
    address public user1;
    uint256 public user1PrivateKey;

    function setUp() public {
        token = new SimpleToken2612("SimpleToken2612", "STK2612", 1_000_000 * 10 ** 18);
        bank = new TokenBank(address(token));

        // use a fixed private key to generate the address
        user1PrivateKey = 0x3389;
        user1 = vm.addr(user1PrivateKey);

        token.transfer(user1, 1000 * 10 ** 18);
    }

    function testDeposit() public {
        vm.startPrank(user1);
        token.approve(address(bank), 500 * 10 ** 18);
        bank.deposit(500 * 10 ** 18);
        vm.stopPrank();

        assertEq(bank.balances(user1), 500 * 10 ** 18);
    }

    function testWithdraw() public {
        vm.startPrank(user1);
        token.approve(address(bank), 500 * 10 ** 18);
        bank.deposit(500 * 10 ** 18);
        uint256 initialBalance = token.balanceOf(user1);
        bank.withdraw(250 * 10 ** 18);
        vm.stopPrank();

        assertEq(bank.balances(user1), 250 * 10 ** 18);
        assertEq(token.balanceOf(user1), initialBalance + 250 * 10 ** 18);
    }

    function testPermitDeposit() public {
        uint256 depositAmount = 500 * 10 ** 18;
        uint256 deadline = block.timestamp + 1 hours;
        console2.log("deadline: %d", deadline);

        // get the nonce
        uint256 nonce = token.nonces(user1);
        console2.log("nonce: %d", nonce);

        // build the permit data
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                user1,
                address(bank),
                depositAmount,
                nonce,
                deadline
            )
        );
        console2.log("structHash: %s", Strings.toHexString(uint256(structHash)));

        // build the digest
        bytes32 domainSeparator = token.DOMAIN_SEPARATOR();
        console2.log("domainSeparator: %s", Strings.toHexString(uint256(domainSeparator)));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        console2.log("digest: %s", Strings.toHexString(uint256(digest)));

        // sign the digest with user1's private key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(user1PrivateKey, digest);
        console2.log("v: %d", v);
        console2.log("r: %s", Strings.toHexString(uint256(r)));
        console2.log("s: %s", Strings.toHexString(uint256(s)));

        // execute permitDeposit
        vm.prank(user1);
        bank.permitDeposit(depositAmount, deadline, v, r, s);

        // verify the result
        assertEq(bank.balances(user1), depositAmount, "Deposit amount should match");
        assertEq(token.balanceOf(address(bank)), depositAmount, "Bank should have received the tokens");
        assertEq(token.balanceOf(user1), 500 * 10 ** 18, "User1 should have 500 tokens left");
    }
}
