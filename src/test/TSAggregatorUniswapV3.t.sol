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

    address tcRouterVault;
    address tcRouterToken;
    uint tcRouterAmount;
    string tcRouterMemo;
    uint tcRouterDeadline;

    TestERC20 weth;
    TestERC20 token;
    TSAggregatorTokenTransferProxy ttp;
    TSAggregatorUniswapV3 agg;

    function setUp() public {
        weth = new TestERC20();
        token = new TestERC20();
        ttp = new TSAggregatorTokenTransferProxy();
        agg = new TSAggregatorUniswapV3(address(ttp), 3000, address(weth), address(this));
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
        token.approve(address(ttp), 50e18);
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
