## THORSwap Aggregators

_Exponentially expand the universe of tokens THORChain supports!_

### Introduction

This repository contains contracts that use AMMs/DEXs together with THORChain
in order to enable swapping from any asset on supported AMMs to any asset on
THORChain in either direction.

For now those aggregator contracts are deployed on the Ethereum mainnet but
could be deployed on any EVM compatible chain that THORChain supports.

### Installing forge for running tests

```
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Installing hardhat for running deployment

```
npm i
```

### SwapIn (ETH/EVM to TC)

To swap tokens from Ethereum to THORChain we essentially need to convert the
user's tokens to ETH. Then use the THORChain router to `deposit` the ETH with
a memo providing the TC asset and address we want to swap to.

In this direction we have a bit less contraints on the complexity/size of the
transaction so it's possible that some more complex AMM including aggregators
like 1inch are supported.

Most aggregator contract have a `swapIn` method that looks like:

```solidity
function swapIn(
    address tcRouter,
    address tcVault,
    string calldata tcMemo,
    address token,
    uint amount,
    uint amountOutMin,
    uint deadline
) public { }
```

|Parameter|Description|
|---|---|
|`tcRouter`|Address of the TC router which we call deposit on (this is a parameter as it changes as they upgrade it over time)|
|`tcVault`|The current vault for the ETH chain (see comment below)|
|`tcMemo`|A [swap memo](https://docs.thorchain.org/developers/transaction-memos) from ETH to the target asset|
|`token`|The ERC20 token to swap to ETH (Input)|
|`amount`|Amount of token to swap|
|`amountOutMin`|Minimum amount of ETH that should be received (slippage protection)|
|`deadline`|Deadline after which the transaction will fail (protects the user again pending transactions due to gas price slippage)|

_The router and vault address can be located in the response to the `/v2/thorchain/inbound_addresses` enpoint of the midgard API_

_The aggregator contract needs to have enough allowance to transfer the user's tokens (`approve` needs to be called before calling `swapIn`)_

### SwapOut (TC to ETH/EVM)

...

### License

MIT
