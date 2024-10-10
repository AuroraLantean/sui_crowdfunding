# Sui Crowdfunding and Pricefeed

## Installation and Setup
Install Sui: https://docs.sui.io/guides/developer/getting-started/sui-install

setup accounts
```
sui --version
make new_addr
make activate_addr
sui client switch --address YOUR_ADDRESS
make balance
make faucet
make activate_testnet
```

#### Supra Pricefeed
https://docs.supra.com/oracles/data-feeds/pull-oracle

Step 1: Create The S-Value Interface
Import interface from https://github.com/Entropy-Foundation/dora-interface git repository and add subdirectory mainnet or testnet for integration.

Step 2: Configure The S-Value Feed Dependency
https://github.com/Entropy-Foundation/dora-interface/tree/master/sui/testnet/supra_holder/sources
Create your project and add the below dependencies in your Move.toml

Copy and paste the (Mainnet or Testnet) pricefeed packageID to the Move.toml

#### Publish Coin
```
sui client publish --gas-budget 50000000
```

Check the transaction digest in Suivision.xyz

Find the PackageID:


Go to SuiScan.xyz and find a list of modules under that package

#### Fungible Coin
