forge script src/scripts/Deploy.s.sol:Deploy \
  --rpc-url https://api.avax.network/ext/bc/C/rpc \
  --private-key $THORSWAP_WALLET_PRIVATE_KEY \
  --etherscan-api-key $THORSWAP_ETHERSCAN_API_KEY \
  --broadcast --verify -vvvv
