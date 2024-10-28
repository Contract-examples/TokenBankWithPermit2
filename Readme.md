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
[PASS] testPermitDeposit() (gas: 206401)
Logs:
  deadline: 1680224400
  nonce: 0
  structHash: 0x7f170ded64521d6a3ec286d8b35492f2dddbc145b265c00f01e88f99121f0596
  domainSeparator: 0x2ad35347a3f6d1126345130dc2ebe7b6a29fc7cac656e73a68221a1995369d4a
  digest: 0x79f5abd9d6ca4f3b3cb92be7579219cc848445245ecd941f5cc8495f6c529533
  v: 0x1b
  r: 0x0d94134e4f5296fa7b60831c8ac8a91fb8656d8855fcf20f0f396b98a93dbd3c
  s: 0x088fbc789319d1621a3a2985beb6d6782107e85243373c8d66954848c49ed588

Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 1.90ms (1.04ms CPU time)
```
