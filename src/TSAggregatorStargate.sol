// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {SafeTransferLib} from "../lib/SafeTransferLib.sol";
import {TSAggregator} from "./TSAggregator.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IOracle} from "./interfaces/IOracle.sol";
import {IStargateRouter} from "./interfaces/IStargateRouter.sol";
import {IThorchainRouter} from "./interfaces/IThorchainRouter.sol";
import {IUniswapRouterV2} from "./interfaces/IUniswapRouterV2.sol";

// 101 1 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 (WETH) Ethereum
// 102 2 0x4Fabb145d64652a948d72533023f6E7A623C7C53 (BUSD) BNB (USDT)
// 106 1 0xfe9A29aB92522D14Fc65880d817214261D8479AE (SNOW) Avalanche
// 109 1 0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0 (MATIC) Polygon
// 110 1 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5 (cETH) Arbitrum
// 111 1 0x030bA81f1c18d280636F32af80b9AAd02Cf0854e (aETH) Optimism
// 112 1 0x4E15361FD6b4BB609Fa63C81A2be19d873717870 (FTM) Fantom

interface ISwapAdapter {
    function swap(address input, address output, uint256 amount, uint256 amountOutMin, address to, bytes calldata data)
        external;
}

contract TSAggregatorStargate is TSAggregator {
    error UnconfiguredChain();
    error UnconfiguredToken();
    error SwapCallReverted();

    using SafeTransferLib for address;

    struct ChainConfig {
        uint256 chainId;
        uint256 poolId;
        address target;
    }

    struct TokenConfig {
        address token;
        address target;
        bytes data;
    }

    uint256 private constant ACTION_SWAP = 1;
    uint256 private constant ACTION_DEPOSIT = 2;
    uint256 public constant sourcePoolId = 1;
    IStargateRouter public stargate;
    IERC20 public bridgeToken;
    IOracle public ethOracle;
    IUniswapRouterV2 public router;
    uint256 public slippage = 100;
    mapping(address => ChainConfig) public chainConfigs;
    mapping(uint256 => TokenConfig) public tokenConfigs;

    event SetChainConfig(address indexed chainToken, uint256 chainId, uint256 poolId, address target);
    event SetTokenConfig(uint256 indexed id, address token, address target, bytes data);
    event SwapTo(address to, address token, uint256 amount, uint256 amountToken, uint256 fee);
    event SwapIn(address from, address token, uint256 amount, uint256 out, uint256 fee, address vault, string memo);
    event SwapOut(address to, address token, uint256 amount, uint256 fee);

    constructor(address _stargate, address _router, address _bridgeToken, address _ethOracle)
        TSAggregator(address(0))
    {
        stargate = IStargateRouter(_stargate);
        bridgeToken = IERC20(_bridgeToken);
        ethOracle = IOracle(_ethOracle);
        router = IUniswapRouterV2(_router);
    }

    function setEthOracle(address _ethOracle) external isOwner {
        ethOracle = IOracle(_ethOracle);
    }

    function setRouter(address _router) external isOwner {
        router = IUniswapRouterV2(_router);
    }

    function setSlippage(uint256 _slippage) external isOwner {
        slippage = _slippage;
    }

    function setChainConfig(address chainToken, uint256 chainId, uint256 poolId, address target) external isOwner {
        chainConfigs[chainToken] = ChainConfig({chainId: chainId, poolId: poolId, target: target});
        emit SetChainConfig(chainToken, chainId, poolId, target);
    }

    function setTokenConfig(uint256 id, address token, address target, bytes calldata data) external isOwner {
        tokenConfigs[id] = TokenConfig({token: token, target: target, data: data});
        emit SetTokenConfig(id, token, target, data);
    }

    // Funds coming from an other chain, we either swap to ETH and deposit into TC,
    // or swap to final target
    function sgReceive(uint16 chainId, bytes memory, uint256, address bridgeToken, uint256 bridgeAmount, bytes memory payload)
        external
    {
        require(msg.sender == address(stargate), "!stargate");
        (uint256 action, bytes memory innerPayload) = abi.decode(payload, (uint256, bytes));
        if (action == ACTION_DEPOSIT) {
            (address tcRouter, address vault, string memory memo, address from, uint256 deadline) =
                abi.decode(innerPayload, (address, address, string, address, uint256));
            uint256 price = uint256(ethOracle.latestAnswer()) * 1e18 / ethOracle.decimals();
            uint256 minAmtOut = _slip(bridgeAmount) * (10 ** IERC20(bridgeToken).decimals()) / price;
            IERC20(bridgeToken).approve(address(router), bridgeAmount);
            address[] memory path = new address[](2);
            path[0] = bridgeToken;
            path[1] = router.WETH();
            try router.swapExactTokensForETH(bridgeAmount, minAmtOut, path, address(this), deadline) {
                uint256 out = address(this).balance;
                uint256 outMinusFee = skimFee(out);
                IThorchainRouter(tcRouter).depositWithExpiry{value: outMinusFee}(
                    payable(vault), address(0), outMinusFee, memo, deadline
                );
                //emit SwapIn(msg.sender, bridgeToken, bridgeAmount, out, out - outMinusFee, vault, memo);
            } catch {
                IERC20(bridgeToken).transfer(from, bridgeAmount);
            }
        } else if (action == ACTION_SWAP) {
            (uint256 tokenId, address to, uint256 amountOutMin) =
                abi.decode(innerPayload, (uint256, address, uint256));
            TokenConfig memory tokenConfig = tokenConfigs[tokenId];
            if (tokenConfig.target == address(0)) revert UnconfiguredToken();
            uint256 amountFee = getFee(bridgeAmount);
            if (amountFee > 0) IERC20(bridgeToken).transfer(feeRecipient, amountFee);
            IERC20(bridgeToken).approve(tokenConfig.target, bridgeAmount - amountFee);
            ISwapAdapter(tokenConfig.target).swap(
                bridgeToken, tokenConfig.token, bridgeAmount - amountFee, amountOutMin, to, tokenConfig.data
            );
        }
    }

    // Takes ETH from a TC swap and sends it to a destination chain for the final leg
    // `token` is not needed (we want to avoid whitelisting) so we reuse it as "target chain"
    // `amountOutMin` is still it's normal self, but the 3 least significant digits
    // are used to specify the "tokenId" on the desitination chain (selects a "TokenConfig")
    function swapOut(address token, address to, uint256 amountOutMin) public payable nonReentrant {
        uint256 tokenId = amountOutMin % 100000 / 100;
        amountOutMin = _parseAmountOutMin(amountOutMin);
        ChainConfig memory chainConfig = chainConfigs[token];
        if (chainConfig.target == address(0)) revert UnconfiguredChain();
        uint256 amount = skimFee(msg.value);

        bytes memory data = abi.encode(ACTION_SWAP, abi.encode(tokenId, to, amountOutMin));
        IStargateRouter.lzTxObj memory txObj = IStargateRouter.lzTxObj(500000, 0, "0x");
        (uint256 fee,) = stargate.quoteLayerZeroFee(
            uint16(chainConfig.chainId), uint8(chainConfig.poolId),
            abi.encodePacked(chainConfig.target), data, txObj
        );

        {
            uint256 price = uint256(ethOracle.latestAnswer()) * 1e18 / ethOracle.decimals();
            uint256 minAmtOut = _slip(amount - fee) * (10 ** bridgeToken.decimals()) / price;
            address[] memory path = new address[](2);
            path[0] = address(router.WETH());
            path[1] = address(bridgeToken);
            router.swapExactETHForTokens{value: amount - fee}(minAmtOut, path, address(this), type(uint256).max);
        }

        stargateSwap(chainConfig.chainId, sourcePoolId, chainConfig.poolId, chainConfig.target, data, to, fee);
    }

    // Takes any token on current chain, swaps to bridge token and initiates a TC deposit
    function swapAndDeposit(
        uint256 targetChainId,
        uint256 targetPoolId,
        address targetContract,
        address token,
        address target,
        bytes calldata data,
        uint256 amount,
        bytes calldata payload
    ) external payable nonReentrant {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        IERC20(token).approve(target, amount);
        {
            (bool success,) = target.call(data);
            if (!success) revert SwapCallReverted();
        }
        // payload = address tcRouter, address vault, string calldata memo, uint256 deadline
        bytes memory data = abi.encode(ACTION_DEPOSIT, payload);
        stargateSwap(targetChainId, sourcePoolId, targetPoolId, targetContract, data, msg.sender, 0);
    }

    // Takes any token on current chain, swaps to bridge token and initiates a swap on the target chain
    function swapAndSwap(
        uint256 targetChainId,
        uint256 targetPoolId,
        address targetContract,
        address token,
        address target,
        bytes calldata data,
        uint256 amount,
        uint256 tokenId,
        uint256 amountOutMin
    ) external payable nonReentrant {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        IERC20(token).approve(target, amount);
        {
            (bool success,) = target.call(data);
            if (!success) revert SwapCallReverted();
        }
        bytes memory data = abi.encode(ACTION_SWAP, abi.encode(tokenId, msg.sender, amountOutMin));
        stargateSwap(targetChainId, sourcePoolId, targetPoolId, targetContract, data, msg.sender, 0);
    }

    function stargateSwap(uint256 targetChainId, uint256 sourcePoolId, uint256 targetPoolId, address targetContract, bytes memory data, address to, uint256 fee) internal {
        uint256 tokenAmount = bridgeToken.balanceOf(address(this));
        bridgeToken.approve(address(stargate), tokenAmount);
        IStargateRouter.lzTxObj memory txObj = IStargateRouter.lzTxObj(500000, 0, "0x");
        if (fee == 0) {
            (fee,) = stargate.quoteLayerZeroFee(
                uint16(targetChainId), uint8(targetPoolId),
                abi.encodePacked(targetContract), data, txObj
            );
        }
        stargate.swap{value: fee}(
            uint16(targetChainId),
            sourcePoolId,
            targetPoolId,
            payable(to),
            tokenAmount,
            _slip(tokenAmount),
            txObj,
            abi.encodePacked(targetContract),
            data
        );
        msg.sender.call{value: address(this).balance}("");
    }

    function getFee(uint256 targetChainId, uint256 targetPoolId) external view returns (uint256) {
        IStargateRouter.lzTxObj memory txObj = IStargateRouter.lzTxObj(500000, 0, "0x");
        bytes memory data = abi.encode(address(0), address(0), "=:ETH.ETH:123456", address(0), 123456);
        (uint256 fee,) = stargate.quoteLayerZeroFee(uint16(targetChainId), uint8(targetPoolId), abi.encodePacked(address(0)), data, txObj);
        return fee;
    }

    function _slip(uint256 amount) internal view returns (uint256) {
        return amount * (10000 - slippage) / 10000;
    }
}
