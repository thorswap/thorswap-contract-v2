// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "./interfaces/IERC20.sol";
import {IStargateRouter} from "./interfaces/IStargateRouter.sol";
import {IUniswapRouterV2} from "./interfaces/IUniswapRouterV2.sol";

contract StargateReceiver {
    IStargateRouter public stargate;
    uint16 public targetChainId = 101;
    uint256 public targetPoolId = 1;
    uint256 public sourcePoolId;
    address public targetContract;

    event SwapOut(address token, address to, uint256 bridgeAmount, uint256 amount); 
    event SwapIn(address token, address to, uint256 bridgeAmount, uint256 amount, uint256 fee); 

    constructor(address _stargate, uint256 _sourcePoolId, address _targetContract) {
        stargate = IStargateRouter(_stargate);
        sourcePoolId = _sourcePoolId;
        targetContract = _targetContract;
    }

    function sgReceive(
        uint16,
        bytes memory,
        uint256,
        address bridgeToken,
        uint256 bridgeAmount,
        bytes memory payload
    ) external {
        require(msg.sender == address(stargate), "!stargate");
        (address token, address router, address[] memory path, address to, uint256 amountOutMin) =
            abi.decode(payload, (address, address, address[], address, uint256));

        IERC20(bridgeToken).approve(router, bridgeAmount);
        if (token == address(0)) {
            uint256 before = to.balance;
            address[] memory path = new address[](2);
            path[0] = bridgeToken;
            path[1] = IUniswapRouterV2(router).WETH();
            try IUniswapRouterV2(router).swapExactTokensForETH(
                bridgeAmount,
                amountOutMin,
                path,
                to,
                type(uint256).max
            ) {
                emit SwapOut(token, to, bridgeAmount, to.balance - before);
            } catch {
                IERC20(bridgeToken).transfer(to, bridgeAmount);
                emit SwapOut(bridgeToken, to, bridgeAmount, bridgeAmount);
            }
        } else {
            uint256 before = IERC20(token).balanceOf(to);
            try IUniswapRouterV2(router).swapExactTokensForTokens(
                bridgeAmount,
                amountOutMin,
                path,
                to,
                type(uint256).max
            ) {
                emit SwapOut(token, to, bridgeAmount, IERC20(token).balanceOf(to) - before);
            } catch {
                IERC20(bridgeToken).transfer(to, bridgeAmount);
                emit SwapOut(bridgeToken, to, bridgeAmount, bridgeAmount);
            }
        }
    }

    function getFee() external view returns (uint256) {
        IStargateRouter.lzTxObj memory txObj = IStargateRouter.lzTxObj(500000, 0, "0x");
        bytes memory data = abi.encode(address(0), address(0), "=:ETH.ETH:123456", address(0), 123456);
        (uint256 fee,) = stargate.quoteLayerZeroFee(
            uint16(101), uint8(1), abi.encodePacked(address(0)), data, txObj
        );
        return fee;
    }

    function swap(address router, address[] calldata path, uint256 amount, uint256 amountOutMin, address tcRouter, address vault, string calldata memo, uint256 deadline) external payable {
        IERC20 token = IERC20(path[0]);
        token.transferFrom(msg.sender, address(this), amount);
        token.approve(router, amount);
        IUniswapRouterV2(router).swapExactTokensForTokens(amount, amountOutMin, path, address(this), deadline);
        uint256 tokenAmount = IERC20(path[path.length-1]).balanceOf(address(this));
        IERC20(path[path.length-1]).approve(address(stargate), tokenAmount);

        IStargateRouter.lzTxObj memory txObj = IStargateRouter.lzTxObj(500000, 0, "0x");
        bytes memory data = abi.encode(tcRouter, vault, memo, msg.sender, deadline);
        (uint256 fee,) = stargate.quoteLayerZeroFee(
            targetChainId, uint8(1), abi.encodePacked(targetContract), data, txObj
        );
        stargate.swap{value: fee}(
            targetChainId,
            sourcePoolId,
            targetPoolId,
            payable(msg.sender),
            tokenAmount,
            tokenAmount * 9900 / 10000,
            txObj,
            abi.encodePacked(targetContract),
            data
        );
        msg.sender.call{value: msg.value - fee}("");
        emit SwapIn(path[0], msg.sender, tokenAmount, amount, fee);
    }
}
