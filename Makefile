-include .env

.PHONY: all clean build remove prove test 
#all targets in your Makefile which do not produce an output file with the same name as the target name should be PHONY.

all: clean remove install update build

clean :; rm -r build
format :; movefmt
build :; sui move build
build2 :; sui move build --skip-fetch-latest-git-deps
test :; sui move test
test2 :; sui move test counter
test3 :; sui move test coin

new_addr :; sui client new-address ed25519
activate_addr :; sui client active-address
addresses :; sui client addresses
switch :; sui client switch --address YOUR_ADDRESS
balance :; sui client balance
gas :; sui client gas
faucet :; sui client faucet
activate_testnet :; sui client switch --env testnet
activate_devnet :; sui client switch --env devnet

publish_coin1 :; sui client publish --gas-budget 50000000 ./sources/coin.move
publish :; sui client publish --gas-budget 50000000 
publish2 :; sui client publish --gas-budget 50000000  --skip-dependency-verification
#./sources/calculator.move
suiscan :; echo "https://suivision.xyz/"

package=0x72bbc6d77698a5d5133bcd7496398f735e7ba5a7c4e8ad61b0c09035e3b234c6
upgradeCap=0xef9ab50c5d3cea4f7e8464337531a632f2709a549656c9f9ba26275c533d9f7f
echo1 :; echo $(package)
initfund :; sui client call --package $(package) --module crowdfunding_pricefeed --function init_fund --args 2 --gas-budget 30000000

fundOwnerCap=0x1e92b79c52ff8e357b616e1562ad5cfc5750c6065cdb7938cf3bb094b3300dc3
fundId=0x9467ec533078b38856abc253e351d7ddb5861c594f7ea670f6cdf312b30f79bd
#https://docs.supra.com/oracles/data-feeds/pull-oracle/networks
SupraSuiOracleHolderTestnet=0x87ef65b543ecb192e89d1e6afeaf38feeb13c3a20c20ce413b29a9cbfbebd570

get_price :; sui client call --package $(package) --module crowdfunding_pricefeed --function get_price_from_client --args $(SupraSuiOracleHolderTestnet) 90

#choose a gasCoinId from "sui client gas"
donate1 :; sui client call --package $(package) --module crowdfunding_pricefeed --function donate --args $(SupraSuiOracleHolderTestnet) $(fundId) 0x36d057015767ce2b9ccd213b8d5f48e0b3f2eb8e8f281d86b9d0367d1ec82175 --gas-budget 30000000

# swtich to another address via addresses & sui client switch --address ... should fail
# swtich to the owner address
withdraw :; sui client call --package $(package) --module crowdfunding_pricefeed --function withdraw_funds --args $(fundOwnerCap) $(fundId) --gas-budget 30000000
# confirm the FundId raised amount is zero

prove :; sui move prove --named-addresses publisher=default

env :; source .env