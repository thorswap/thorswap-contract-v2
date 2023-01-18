forge verify-contract \
  --chain-id 1 --num-of-optimizations 200 \ # eth 1 avax 43114
  --compiler-version 0.8.10+commit.fc410830 \
  --constructor-args `cast abi-encode "constructor(address)" "0xF892Fef9dA200d9E84c9b0647ecFF0F34633aBe8"` \
  0x77cdf20e2442CD38C0A704e370fe8a75107AbD95 \
  src/TSAggregatorGeneric.sol:TSAggregatorGeneric $THORSWAP_ETHERSCAN_API_KEY
