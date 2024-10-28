// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@permit2/interfaces/IPermit2.sol";
import "@permit2/interfaces/ISignatureTransfer.sol";
import "../src/TokenBank.sol";
import "../src/SimpleToken2612.sol";

contract TokenBankTest is Test {
    TokenBank public bank;
    SimpleToken2612 public token;
    IPermit2 public permit2;
    address public user1;
    uint256 public user1PrivateKey;

    // Permit2 contract address
    address constant PERMIT2_ADDRESS = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    function setUp() public {
        // deploy permit2
        permit2 = IPermit2(deployCode("../test/Permit2.sol:Permit2"));
        console2.log("permit2");
        // Deploy token and bank
        token = new SimpleToken2612("SimpleToken2612", "STK2612", 1_000_000 * 10 ** 18);
        bank = new TokenBank(address(token), address(permit2));

        // Setup user1
        user1PrivateKey = 0x3389;
        user1 = vm.addr(user1PrivateKey);

        // Transfer tokens to user1
        token.transfer(user1, 1000 * 10 ** 18);

        // User approves Permit2
        vm.startPrank(user1);
        token.approve(address(permit2), type(uint256).max);
        vm.stopPrank();
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

        // no need to call approve, because the bank is the spender
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
        console2.log("v: %s", Strings.toHexString(uint256(v)));
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

    function testDepositWithPermit2() public {
        uint256 depositAmount = 500 * 10 ** 18;
        uint256 nonce = 0;
        uint256 deadline = block.timestamp + 1 hours;

        // Create permit message
        ISignatureTransfer.PermitTransferFrom memory permit = ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({ token: address(token), amount: depositAmount }),
            nonce: nonce,
            deadline: deadline
        });

        console2.log("Initial user balance: %d", token.balanceOf(user1));
        console2.log("Initial bank balance: %d", token.balanceOf(address(bank)));
        console2.log("Permit2 allowance: %d", token.allowance(user1, address(permit2)));

        bytes32 digest = _getPermitTransferFromDigest(permit, address(bank), address(permit2));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(user1PrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Execute deposit with permit2
        vm.prank(user1);
        bank.depositWithPermit2(depositAmount, nonce, deadline, signature);

        // Verify deposit
        assertEq(bank.balances(user1), depositAmount, "Bank balance should match deposit amount");
        assertEq(token.balanceOf(address(bank)), depositAmount, "Bank token balance should increase by deposit amount");
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
        console2.log("DOMAIN_SEPARATOR: %s", vm.toString(DOMAIN_SEPARATOR));

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
}
