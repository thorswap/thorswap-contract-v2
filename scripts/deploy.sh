forge script src/scripts/Deploy.s.sol:Deploy \
  --rpc-url https://mainnet.infura.io/v3/f9dfccab907d4cc891817733689eaff4  \
  --private-key $THORSWAP_WALLET_PRIVATE_KEY \
  --etherscan-api-key $THORSWAP_ETHERSCAN_API_KEY \
  --broadcast --verify -vvvv
