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
Logs:
  permit2
  Initial user balance: 1000000000000000000000
  Initial bank balance: 0
  Permit2 allowance: 115792089237316195423570985008687907853269984665640564039457584007913129639935
  DOMAIN_SEPARATOR: 0x01eadfe56143d8d1f420bcedaec8631185e5b833c351845caa4803a35fb9837a
  digest: 0x297c66ca59999d20eb797499bb7ec8f1a43c3bbc961d49b004204a8c4647041a
  v: 0x1c
  r: 0xea30c8ccf0ae7ffc42e8eea408db10bec34d08af6d6786733b4a10f81866b8e5
  s: 0x761507d311654ddc509a4a11fe59c12f41775fc6a8bb035e8aa918c8de7b7b19
  signature:
  0xea30c8ccf0ae7ffc42e8eea408db10bec34d08af6d6786733b4a10f81866b8e5761507d311654ddc509a4a11fe59c12f41775fc6a8bb035e8aa918c8de7b7b191c  
  bank balance: 500000000000000000000
  bank token balance: 500000000000000000000

Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 2.39ms (984.30µs CPU time)

Ran 1 test suite in 9.35ms (2.39ms CPU time): 1 tests passed, 0 failed, 0 skipped (1 total tests)
```

## Deploy
```
forge script script/Deploy.s.sol:DeployScript --rpc-url arbitrum_sepolia --broadcast --verify -vvvv
```
