# Token bank with uniswap(permit2)

## Install deps
```
forge install
```

## Test
```
forge test --match-test=testDepositWithPermit2 -vv
```

## The result of testing
```
Ran 1 test for test/TokenBank.t.sol:TokenBankTest
[PASS] testDepositWithPermit2() (gas: 124719)
Logs:
  permit2
  Initial user balance: 1000000000000000000000
  Initial bank balance: 0
  Permit2 allowance: 115792089237316195423570985008687907853269984665640564039457584007913129639935
  DOMAIN_SEPARATOR: 0x01eadfe56143d8d1f420bcedaec8631185e5b833c351845caa4803a35fb9837a

Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 1.93ms (691.10µs CPU time)
```
