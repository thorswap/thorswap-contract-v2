// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {DSTest} from "../../lib/DSTest.sol";
import {TSAggregatorUniswapV2} from "../TSAggregatorUniswapV2.sol";
import {TSAggregatorUniswapV3} from "../TSAggregatorUniswapV3.sol";

contract Deploy is DSTest {
    function run() external {
        address ttp = 0xF892Fef9dA200d9E84c9b0647ecFF0F34633aBe8;
        address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address routerv2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        address routerv3 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
        address routersushi = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
        address ms = 0x8F692D7abC6cDf567571276f76112Ec9A01DE309;
        uint256 fee = 30;
        address feeRecipient = 0x7D8911eB1C72F0Ba29302bE30301B75Cec81F622;
        vm.startBroadcast();
        TSAggregatorUniswapV2 av2 = new TSAggregatorUniswapV2(ttp, weth, routerv2);
        TSAggregatorUniswapV2 ass = new TSAggregatorUniswapV2(ttp, weth, routersushi);
        TSAggregatorUniswapV3 av3100 = new TSAggregatorUniswapV3(ttp, weth, routerv3, 100);
        TSAggregatorUniswapV3 av3500 = new TSAggregatorUniswapV3(ttp, weth, routerv3, 500);
        TSAggregatorUniswapV3 av33000 = new TSAggregatorUniswapV3(ttp, weth, routerv3, 3000);
        TSAggregatorUniswapV3 av310000 = new TSAggregatorUniswapV3(ttp, weth, routerv3, 10000);
        av2.setOwner(ms, true);
        ass.setOwner(ms, true);
        av3100.setOwner(ms, true);
        av3500.setOwner(ms, true);
        av33000.setOwner(ms, true);
        av310000.setOwner(ms, true);
        av2.setFee(fee, feeRecipient);
        ass.setFee(fee, feeRecipient);
        av3100.setFee(fee, feeRecipient);
        av3500.setFee(fee, feeRecipient);
        av33000.setFee(fee, feeRecipient);
        av310000.setFee(fee, feeRecipient);
        vm.stopBroadcast();
    }
}
