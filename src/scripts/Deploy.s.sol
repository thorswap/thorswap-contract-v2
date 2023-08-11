// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {DSTest} from "../../lib/DSTest.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {TSAggregatorTokenTransferProxy} from "../TSAggregatorTokenTransferProxy.sol";
import {TSAggregatorStargate} from "../TSAggregatorStargate.sol";
import {StargateReceiver} from "../StargateReceiver.sol";
import {SwapAdapterUniswapV2} from "../SwapAdapterUniswapV2.sol";

contract Deploy is DSTest {
    function run() external {
        //*
        // Ethereum Mainnet
        address ttp = 0xF892Fef9dA200d9E84c9b0647ecFF0F34633aBe8;
        address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address routerv2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        address routerv3 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
        address routersushi = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
        address ms = 0x8F692D7abC6cDf567571276f76112Ec9A01DE309;
        uint256 fee = 30;
        address feeRecipient = 0x7D8911eB1C72F0Ba29302bE30301B75Cec81F622;
        //*/

        /*
        // Avalanche Mainnet
        address wavax = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
        address deployer = 0xE30c6b39c91A4bb6fD734dae898B63985213032e;
        address ms = 0xC510D02ceE9eF8D9BFb880b212ff0e3A5C46a6BE;
        uint256 fee = 30;
        address feeRecipient = 0xC510D02ceE9eF8D9BFb880b212ff0e3A5C46a6BE;
        address ttp = 0x69ba883Af416fF5501D54D5e27A1f497fBD97156;
        address routerjoe = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
        address routerpangolin = 0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106;
        address routerwoofi = 0xC22FBb3133dF781E6C25ea6acebe2D2Bb8CeA2f9;
        //*/

        vm.startBroadcast();
        //new UniswapV2CamelotAdapter(0xc873fEcbd354f5A56E00E710B90EF4201db2448d);

        //// AGGREGATOR
        // 0x8731d54E9D02c286767d56ac03e8037C07e01e98 Stargate Ethereum
        // 0x45A01E4e04F14f7A4a6702c74187c5F6222033cd Stargate Avalanche
        // 0x45A01E4e04F14f7A4a6702c74187c5F6222033cd Stargate Polygon
        // 0x53Bf833A5d6c4ddA888F69c22C88C9f356a41614 Stargate Arbitrum
        // 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 USDC Ethereum
        // 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8 USDC Arbitrum
        //TSAggregatorStargate agg = new TSAggregatorStargate(
        //    0x53Bf833A5d6c4ddA888F69c22C88C9f356a41614, // StargateRouter
        //    address(0), // routerv2
        //    0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8, // bridgeToken USDC
        //    address(0) // 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 // ethOracle
        //);
        //TSAggregatorStargate agg = TSAggregatorStargate(payable(0x48f68ff093b3b3A80D2FC97488EaD97E16b86283));
        //address[] memory path = new address[](3);
        //path[0] = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
        //path[1] = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
        //path[2] = 0x912CE59144191C1204E64559FE8253a0e49E6548;
        //agg.setTokenConfig(1, 0x912CE59144191C1204E64559FE8253a0e49E6548, 0x17e7e5016ac1D4527F211bEbf5b11FE36bda7D10, abi.encode(path));

        //TSAggregatorStargate agg = TSAggregatorStargate(payable(0x1204b5Bf0D6d48E718B1d9753A4166A7258B8432));
        //agg.setFee(fee, feeRecipient);
        //agg.setChainConfig(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5, 110, 1, 0x55cF4D1E35221F0a7EF3F5D1ce5a07E3EcdB25B2);
        //agg.setOwner(ms, true);
        //agg.setOwner(address(this), false);
        //TSAggregatorTokenTransferProxy(ttp).setOwner(address(agg), true);

        //// CROSS-CHAIN RECEIVER
        //new StargateReceiver(
        //    //0x45A01E4e04F14f7A4a6702c74187c5F6222033cd, // Stargate Avalanche
        //    //0x45A01E4e04F14f7A4a6702c74187c5F6222033cd, // Stargate Polygon
        //    //0x53Bf833A5d6c4ddA888F69c22C88C9f356a41614, // Stargate Arbitrum
        //    1,
        //    0x1204b5Bf0D6d48E718B1d9753A4166A7258B8432
        //);

        //// SWAP OUT
        //TSAggregatorStargate(payable(0x1204b5Bf0D6d48E718B1d9753A4166A7258B8432)).swapOut{value: 0.0075e18}(
        //    address(0), 0xE30c6b39c91A4bb6fD734dae898B63985213032e, 100100
        //);

        // SWAP IN
        //address[] memory path = new address[](3);
        //path[0] = 0x912CE59144191C1204E64559FE8253a0e49E6548;
        //path[1] = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
        //path[2] = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
        //IERC20(path[0]).approve(0xb1970f2157a1B24D40f98b252F4F60b45c7AaeED, type(uint256).max);
        //uint256 f = StargateReceiver(0xb1970f2157a1B24D40f98b252F4F60b45c7AaeED).getFee();
        //uint256 b = IERC20(path[0]).balanceOf(0xE30c6b39c91A4bb6fD734dae898B63985213032e);
        //StargateReceiver(0xb1970f2157a1B24D40f98b252F4F60b45c7AaeED).swap{value: f}(
        //    0xdC01894a2559417F08edAF5F3B3AdFAa89D28C8E, path, b, 10e6,
        //    0xD37BbE5744D730a1d98d8DC97c42F0Ca46aD7146,
        //    0xea7684E0Fe44bc67c74DF69ceeBa23d3B4404D68,
        //    "=:THOR.RUNE:t",
        //    type(uint256).max
        //);

        vm.stopBroadcast();
    }
}
