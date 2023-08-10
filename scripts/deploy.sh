export RPC_URL_ETHEREUM=https://rpc.ankr.com/eth
export RPC_URL_AVALANCHE=https://api.avax.network/ext/bc/C/rpc
export RPC_URL_POLYGON=https://polygon.llamarpc.com
export RPC_URL_ARBITRUM=https://endpoints.omniatech.io/v1/arbitrum/one/public
forge script src/scripts/Deploy.s.sol:Deploy \
  --rpc-url $RPC_URL_ARBITRUM \
  --private-key $THORSWAP_WALLET_PRIVATE_KEY \
  --etherscan-api-key $THORSWAP_ETHERSCAN_API_KEY_ARBITRUM \
  --broadcast --verify -vvvv --legacy --slow
