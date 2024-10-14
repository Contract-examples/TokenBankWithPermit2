# Token bank

### Create a ``.env`` file
```
API_KEY_INFURA=your infura api key 
API_KEY_ARBISCAN=your arbiscan api key 
SEPOLIA_WALLET_PRIVATE_KEY=your wallet private key 
BANK_CONTRACT_ADDRESS=your contract address
TOKEN_CONTRACT_ADDRESS=your erc20 token address
```


## Deploy to Arbitrum-Sepolia
```
forge script script/Deploy.s.sol:DeployTokenBankAndTokenScript --rpc-url arbitrum_sepolia --broadcast --verify -vvvv
```

## Token address
- https://sepolia.arbiscan.io/address/0x01656ba9826a86dec6cd8b0c38eaf5270e2fbc28#events

## Tokenbank address
- https://sepolia.arbiscan.io/address/0x0368ad1a77e9e03ff2b34bfc453ae6d166ed6be5#code

## Distribute 1000 tokens to ``0xe091701aC9816D38241887147B41AE312d26e1C3``
```
forge script script/DistributeSimpleToken.s.sol:DistributeSimpleTokenScript --rpc-url arbitrum_sepolia --broadcast -vvvv
```
txhash: https://sepolia.arbiscan.io/tx/0xdb8efe967a12637d979d2ff48a3d339841469d918bb6d77eda5522445bf3f742
