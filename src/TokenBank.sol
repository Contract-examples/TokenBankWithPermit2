// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@permit2/interfaces/IPermit2.sol";
import "@permit2/interfaces/ISignatureTransfer.sol";

contract TokenBank {
    using SafeERC20 for IERC20;
    using Address for address;

    // token
    IERC20 public immutable token;
    IERC20Permit public immutable tokenPermit;
    bool public immutable supportsPermit;

    // user => balance
    mapping(address => uint256) public balances;

    // error
    error DepositTooLow();
    error InsufficientBalance();
    error TransferFailedForDeposit();
    error TransferFailedForWithdraw();
    error PermitNotSupported();
    error WithdrawTooLow();

    // event
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    // permit2 contract
    IPermit2 public immutable permit2;

    constructor(address _token, address _permit2) {
        token = IERC20(_token);
        permit2 = IPermit2(_permit2);

        // check if the token supports permit
        supportsPermit = _isPermitSupported(_token);

        if (supportsPermit) {
            tokenPermit = IERC20Permit(_token);
        }
    }

    // this is a helper function to check if the recipient is a contract
    function _isContract(address account) internal view returns (bool) {
        // if the code size is greater than 0, then the account is a contract
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    // check if the token supports permit
    function _isPermitSupported(address _token) internal view returns (bool) {
        if (!_isContract(_token)) {
            return false;
        }
        try IERC20Permit(_token).DOMAIN_SEPARATOR() returns (bytes32) {
            return true;
        } catch {
            return false;
        }
    }

    function deposit(uint256 amount) public {
        // if amount is 0, revert
        if (amount == 0) {
            revert DepositTooLow();
        }

        // get balance before
        uint256 balanceBefore = token.balanceOf(address(this));

        // transfer token from user to contract (safe transfer)
        token.safeTransferFrom(msg.sender, address(this), amount);

        // get balance after
        uint256 balanceAfter = token.balanceOf(address(this));

        // if balance after is less than balance before, revert
        if (balanceAfter < balanceBefore) {
            revert TransferFailedForDeposit();
        }

        // update balance
        balances[msg.sender] += amount;

        // emit event
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        // if amount is 0, revert
        if (amount == 0) {
            revert WithdrawTooLow();
        }

        // if amount > balance, revert
        if (amount > balances[msg.sender]) {
            revert InsufficientBalance();
        }

        // get balance before
        uint256 balanceBefore = token.balanceOf(address(this));

        // transfer token from contract to user (safe transfer)
        token.safeTransfer(msg.sender, amount);

        // get balance after
        uint256 balanceAfter = token.balanceOf(address(this));

        // if balance after is greater than balance before, revert
        if (balanceAfter > balanceBefore) {
            revert TransferFailedForWithdraw();
        }

        // update balance
        balances[msg.sender] -= amount;

        // emit event
        emit Withdraw(msg.sender, amount);
    }

    // Query contract balance
    function getBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    // Query specific depositor's deposit amount
    function getDepositAmount(address depositor) public view returns (uint256) {
        return balances[depositor];
    }

    function permitDeposit(uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        if (!supportsPermit) {
            revert PermitNotSupported();
        }

        // permit
        tokenPermit.permit(msg.sender, address(this), amount, deadline, v, r, s);

        // deposit
        deposit(amount);
    }

    // permit2 deposit
    function depositWithPermit2(uint256 amount, uint256 nonce, uint256 deadline, bytes calldata signature) external {
        if (amount == 0) {
            revert DepositTooLow();
        }

        // Create permit message
        ISignatureTransfer.PermitTransferFrom memory permit = ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({ token: address(token), amount: amount }),
            nonce: nonce,
            deadline: deadline
        });

        // get balance before
        uint256 balanceBefore = token.balanceOf(address(this));

        // Create transfer details
        ISignatureTransfer.SignatureTransferDetails memory transferDetails =
            ISignatureTransfer.SignatureTransferDetails({ to: address(this), requestedAmount: amount });

        // get balance after
        uint256 balanceAfter = token.balanceOf(address(this));

        // if balance after is less than balance before, revert
        if (balanceAfter < balanceBefore) {
            revert TransferFailedForDeposit();
        }

        // Execute permit transfer
        permit2.permitTransferFrom(permit, transferDetails, msg.sender, signature);

        // update balance
        balances[msg.sender] += amount;

        // emit event
        emit Deposit(msg.sender, amount);
    }
}
