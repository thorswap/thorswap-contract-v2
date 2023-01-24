// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {DSTest} from "../../lib/DSTest.sol";
import {TSAggregatorUniswapV3} from "../TSAggregatorUniswapV3.sol";
import {TSAggregatorTokenTransferProxy} from "../TSAggregatorTokenTransferProxy.sol";

contract Deploy is DSTest {
    function run() external {
        // Ethereum Mainnet
        address ttp = 0xF892Fef9dA200d9E84c9b0647ecFF0F34633aBe8;
        address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address routerv2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        address routerv3 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
        address routersushi = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
        address ms = 0x8F692D7abC6cDf567571276f76112Ec9A01DE309;
        uint256 fee = 30;
        address feeRecipient = 0x7D8911eB1C72F0Ba29302bE30301B75Cec81F622;

        /*
        // Avalanche Mainnet
        address wavax = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
        address ms = 0xC510D02ceE9eF8D9BFb880b212ff0e3A5C46a6BE;
        uint256 fee = 30;
        address feeRecipient = 0xC510D02ceE9eF8D9BFb880b212ff0e3A5C46a6BE;
        address ttp = 0x69ba883Af416fF5501D54D5e27A1f497fBD97156;
        address routerjoe = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
        address routerpangolin = 0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106;
        */

        vm.startBroadcast();
        TSAggregatorUniswapV3 agg = new TSAggregatorUniswapV3(ttp, weth, routerv3, 10000);
        agg.setOwner(ms, true);
        agg.setFee(fee, feeRecipient);
        TSAggregatorTokenTransferProxy(ttp).setOwner(address(agg), true);
        vm.stopBroadcast();
    }
}
