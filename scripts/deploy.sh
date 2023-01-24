export RPC_URL_ETHEREUM=https://rpc.ankr.com/eth
export RPC_URL_AVALANCHE=https://api.avax.network/ext/bc/C/rpc
forge script src/scripts/Deploy.s.sol:Deploy \
  --rpc-url $RPC_URL_ETHEREUM \
  --private-key $THORSWAP_WALLET_PRIVATE_KEY \
  --etherscan-api-key $THORSWAP_ETHERSCAN_API_KEY \
  --broadcast --verify -vvvv
