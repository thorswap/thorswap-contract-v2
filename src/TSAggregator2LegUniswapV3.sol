// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import { SafeTransferLib } from "../lib/SafeTransferLib.sol";
import { IWETH9 } from "./interfaces/IWETH9.sol";
import { TSAggregator } from "./TSAggregator.sol";
import { IThorchainRouter } from "./interfaces/IThorchainRouter.sol";
import { IUniswapRouterV3 } from "./interfaces/IUniswapRouterV3.sol";

contract TSAggregator2LegUniswapV3 is TSAggregator {
    using SafeTransferLib for address;

    IWETH9 public weth;
    uint24 public poolFee;
    IUniswapRouterV3 public swapRouter;
    address public legToken;
    uint24 public legPoolFee;

    event SwapIn(address from, address token, uint256 amount, uint256 out, uint256 fee, address vault, string memo);
    event SwapOut(address to, address token, uint256 amount, uint256 fee);

    constructor(
        address _ttp, uint24 _poolFee, address _weth, address _swapRouter,
        address _legToken, uint24 _legPoolFee
    ) TSAggregator(_ttp) {
        weth = IWETH9(_weth);
        poolFee = _poolFee;
        swapRouter = IUniswapRouterV3(_swapRouter);
        legToken = _legToken;
        legPoolFee = _legPoolFee;
    }

    function swapIn(
        address vault,
        string calldata memo,
        address token,
        uint amount,
        uint amountOutMin,
        uint deadline
    ) public nonReentrant {
        tokenTransferProxy.transferTokens(token, msg.sender, address(this), amount);
        token.safeApprove(address(swapRouter), 0); // USDT quirk
        token.safeApprove(address(swapRouter), amount);

        bytes memory path = abi.encodePacked(token, poolFee, legToken, legPoolFee, address(weth));
        uint out = swapRouter.exactInput(IUniswapRouterV3.ExactInputParams({
            path: path,
            recipient: address(this),
            deadline: deadline,
            amountIn: amount,
            amountOutMinimum: amountOutMin
        }));
        weth.withdraw(out);

        uint outMinusFee = skimFee(out);
        vault.call{value: outMinusFee}(bytes(memo));
        emit SwapIn(msg.sender, token, amount, out, out-outMinusFee, vault, memo);
    }

    function swapOut(address token, address to, uint256 amountOutMin) public payable nonReentrant {
        uint256 amount = skimFee(msg.value);
        bytes memory path = abi.encodePacked(address(weth), legPoolFee, legToken, poolFee, token);
        weth.deposit{value: amount}();
        address(weth).safeApprove(address(swapRouter), amount);
        swapRouter.exactInput(IUniswapRouterV3.ExactInputParams({
            path: path,
            recipient: to,
            deadline: type(uint).max,
            amountIn: amount,
            amountOutMinimum: _parseAmountOutMin(amountOutMin)
        }));
        emit SwapOut(to, token, msg.value, msg.value-amount);
    }
}
