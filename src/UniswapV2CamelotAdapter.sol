// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "./interfaces/IERC20.sol";

interface IUniswapRouterV2Camelot {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;
}

contract UniswapV2CamelotAdapter {
    IUniswapRouterV2Camelot public router; 

    constructor(address _router) {
        router = IUniswapRouterV2Camelot(_router);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        IERC20(path[0]).approve(address(router), amountIn);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            address(0),
            deadline
        );
    }
}
