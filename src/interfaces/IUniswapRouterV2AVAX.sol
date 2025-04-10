// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IUniswapRouterV2AVAX {
    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactAVAXForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to, uint deadline
    ) external payable;
}
