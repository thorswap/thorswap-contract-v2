// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {DSTest} from "../../lib/DSTest.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {TSAggregatorTokenTransferProxy} from "../TSAggregatorTokenTransferProxy.sol";
import {TSAggregatorStargate} from "../TSAggregatorStargate.sol";
import {StargateReceiver} from "../StargateReceiver.sol";
import {UniswapV2CamelotAdapter} from "../UniswapV2CamelotAdapter.sol";

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
        //TSAggregatorStargate agg = new TSAggregatorStargate(
        //    0x8731d54E9D02c286767d56ac03e8037C07e01e98, // StargateRouter
        //    routerv2,
        //    0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, // bridgeToken USDC
        //    0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 // ethOracle
        //);
        //TSAggregatorStargate agg = TSAggregatorStargate(payable(0x1204b5Bf0D6d48E718B1d9753A4166A7258B8432));
        //address[] memory path = new address[](3);
        //path[0] = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
        //path[1] = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
        //path[2] = 0x912CE59144191C1204E64559FE8253a0e49E6548;
        //agg.setTokenConfig(
        //    1, 110,
        //    path[path.length-1],
        //    //0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff, // QuickSwap
        //    //0xc873fEcbd354f5A56E00E710B90EF4201db2448d, // Camelot V2
        //    0xdC01894a2559417F08edAF5F3B3AdFAa89D28C8E, // Camelot V2 Wrapper
        //    path
        //);
        //agg.setFee(fee, feeRecipient);
        //agg.setOwner(ms, true);
        //agg.setOwner(address(this), false);
        //agg.setChainTargetContract(106, 0xdC01894a2559417F08edAF5F3B3AdFAa89D28C8E);
        //agg.setChainTargetContract(109, 0x082F52eEAc890248F00A24B4ddec6eFb55b61850);
        //agg.setChainTargetContract(110, 0xb1970f2157a1B24D40f98b252F4F60b45c7AaeED);
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

        //// SWAP IN
        //address[] memory path = new address[](3);
        //path[0] = 0x580A84C73811E1839F75d86d75d88cCa0c241fF4;
        //path[1] = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
        //path[2] = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
        //IERC20(0x580A84C73811E1839F75d86d75d88cCa0c241fF4).approve(0xb1970f2157a1B24D40f98b252F4F60b45c7AaeED, type(uint256).max);
        //StargateReceiver(0xb1970f2157a1B24D40f98b252F4F60b45c7AaeED).swap{value:36568725491667431362}(
        //    0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff, path, 1641746111448940083419, 50000000,
        //    0xD37BbE5744D730a1d98d8DC97c42F0Ca46aD7146,
        //    0xbDF348cd961e303B484928BcB2fE0Bd6D4Ee0855,
        //    "=:ETH.USDC",
        //    type(uint256).max
        //);
        vm.stopBroadcast();
    }
}
