# Token bank with permit

## Test
```
forge test -vv
```

## The result of testing
```
Ran 3 tests for test/TokenBank.t.sol:TokenBankTest
[PASS] testDeposit() (gas: 79013)
[PASS] testPermitDeposit() (gas: 119870)
Logs:
  nonce: 0

[PASS] testWithdraw() (gas: 88141)
Suite result: ok. 3 passed; 0 failed; 0 skipped; finished in 1.65ms (1.26ms CPU time)

Ran 1 test suite in 8.09ms (1.65ms CPU time): 3 tests passed, 0 failed, 0 skipped (3 total tests)
```
