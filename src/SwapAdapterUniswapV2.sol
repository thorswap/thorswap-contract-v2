// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "./interfaces/IERC20.sol";

interface IUniswapRouterV2 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;
}

contract SwapAdapterUniswapV2 {
    IUniswapRouterV2 public router; 

    constructor(address _router) {
        router = IUniswapRouterV2(_router);
    }

    function swap(
        address input,
        address output,
        uint256 amount,
        uint256 amountOutMin,
        address to,
        bytes calldata data
    ) external {
        IERC20(input).transferFrom(msg.sender, address(this), amount);
        IERC20(input).approve(address(router), amount);
        address[] memory path = abi.decode(data, (address[]));
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            amountOutMin,
            path,
            to,
            address(0),
            type(uint256).max
        );
    }
}
