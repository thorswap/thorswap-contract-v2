// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import { DSTest } from "../../lib/DSTest.sol";
import { TestERC20 } from "./TestERC20.sol";
import { TSAggregatorTokenTransferProxy } from "../TSAggregatorTokenTransferProxy.sol";
import { TSAggregatorUniswapV3, IUniswapRouterV3 } from "../TSAggregatorUniswapV3.sol";

contract TSAggregatorUniswapV3Test is DSTest {
    uint swapRouterAmount;
    uint swapRouterAmountOutMin;
    address swapRouterPath0;
    address swapRouterPath1;
    address swapRouterTo;
    uint swapRouterDeadline;

    TestERC20 weth;
    TestERC20 token;
    TSAggregatorTokenTransferProxy ttp;
    TSAggregatorUniswapV3 agg;

    function setUp() public {
        weth = new TestERC20();
        token = new TestERC20();
        ttp = new TSAggregatorTokenTransferProxy();
        agg = new TSAggregatorUniswapV3(address(ttp), address(weth), address(this), 3000);
        ttp.setOwner(address(agg), true);
        agg.setFee(500, vm.addr(2));
    }

    function exactInputSingle(IUniswapRouterV3.ExactInputSingleParams calldata params) public returns (uint) {
        swapRouterAmount = params.amountIn;
        swapRouterAmountOutMin = params.amountOutMinimum;
        swapRouterPath0 = params.tokenIn;
        swapRouterPath1 = params.tokenOut;
        swapRouterTo = params.recipient;
        swapRouterDeadline = params.deadline;
        vm.deal(address(this), 2e18);
        weth.deposit{value: 2e18}();
        weth.transfer(msg.sender, 2e18);
        return 2e18;
    }

    function testSwapIn() public {
        token.mintTo(address(this), 50e18);
        token.approve(address(ttp), 50e18);
        agg.swapIn(
            vm.addr(1),
            "SWAP:...",
            address(token),
            50e18,
            4e18,
            1234
        );
        assertEq(swapRouterAmount, 50e18);
        assertEq(swapRouterAmountOutMin, 4e18);
        assertEq(swapRouterPath0, address(token));
        assertEq(swapRouterPath1, address(weth));
        assertEq(vm.addr(1).balance, 19e17);
    }

    function testSwapOut() public {
        vm.deal(address(this), 5e17);
        agg.swapOut{value: 5e17}(address(token), vm.addr(1), 412);
        assertEq(weth.allowance(address(agg), address(this)), 475e15);
        assertEq(weth.balanceOf(address(agg)), 2475e15);
        assertEq(swapRouterAmount, 475e15);
        assertEq(swapRouterAmountOutMin, 4e12);
        assertEq(swapRouterPath0, address(weth));
        assertEq(swapRouterPath1, address(token));
    }
}
