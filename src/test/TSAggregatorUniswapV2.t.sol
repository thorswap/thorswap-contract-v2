// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import { DSTest } from "../../lib/DSTest.sol";
import { TestERC20 } from "./TestERC20.sol";
import { TSAggregatorUniswapV2 } from "../TSAggregatorUniswapV2.sol";

contract TSAggregatorUniswapV2Test is DSTest {
    uint swapRouterAmount;
    uint swapRouterAmountOutMin;
    address swapRouterPath0;
    address swapRouterPath1;
    address swapRouterTo;
    uint swapRouterDeadline;

    address tcRouterVault;
    address tcRouterToken;
    uint tcRouterAmount;
    string tcRouterMemo;
    uint tcRouterDeadline;

    TestERC20 weth;
    TestERC20 token;
    TSAggregatorUniswapV2 agg;

    function setUp() public {
        weth = new TestERC20();
        token = new TestERC20();
        agg = new TSAggregatorUniswapV2(address(weth), address(this));
        agg.setFee(500, vm.addr(2));
    }

    function swapExactTokensForETH(
        uint amount, uint amountOutMin, address[] calldata path, address to, uint deadline
    ) public {
        swapRouterAmount = amount;
        swapRouterAmountOutMin = amountOutMin;
        swapRouterPath0 = path[0];
        swapRouterPath1 = path[1];
        swapRouterTo = to;
        swapRouterDeadline = deadline;
        vm.deal(msg.sender, 2e18);
    }

    function depositWithExpiry(
        address vault, address token, uint amount, string calldata memo, uint deadline
    ) public payable {
        tcRouterVault = vault;
        tcRouterToken = token;
        tcRouterAmount = amount;
        tcRouterMemo = memo;
        tcRouterDeadline = deadline;
    }

    function testSwapIn() public {
        token.mintTo(address(this), 50e18);
        token.approve(address(agg), 50e18);
        agg.swapIn(
            address(this),
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
        assertEq(tcRouterVault, vm.addr(1));
        assertEq(tcRouterMemo, "SWAP:...");
        assertEq(tcRouterToken, address(0));
        assertEq(tcRouterAmount, 19e17);
    }
}
