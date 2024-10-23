// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
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

        // get the nonce
        uint256 nonce = token.nonces(user1);
        console2.log("nonce: %s", nonce);

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

        bytes32 domainSeparator = token.DOMAIN_SEPARATOR();
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        // sign the digest with user1's private key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(user1PrivateKey, digest);

        // execute permitDeposit
        vm.prank(user1);
        bank.permitDeposit(depositAmount, deadline, v, r, s);

        // verify the result
        assertEq(bank.balances(user1), depositAmount, "Deposit amount should match");
        assertEq(token.balanceOf(address(bank)), depositAmount, "Bank should have received the tokens");
        assertEq(token.balanceOf(user1), 500 * 10 ** 18, "User1 should have 500 tokens left");
    }
}
