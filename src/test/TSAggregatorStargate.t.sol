// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import { DSTest } from "../../lib/DSTest.sol";
import { TestERC20 } from "./TestERC20.sol";
import { TSAggregatorStargate } from "../TSAggregatorStargate.sol";
import { IStargateRouter } from "../interfaces/IStargateRouter.sol";

contract TSAggregatorStargateTest is DSTest {
    TestERC20 swapToken;
    TestERC20 bridgeToken;
    TSAggregatorStargate c;

    function setUp() public {
        swapToken = new TestERC20();
        bridgeToken = new TestERC20();
        c = new TSAggregatorStargate(address(this), address(this), address(bridgeToken), address(this));
        c.setFee(30, vm.addr(1));
    }

    function testSetSlippage() public {
        c.setSlippage(123);
        assertEq(c.slippage(), 123);
    }

    function testChainTargetContact() public {
        c.setChainTargetContract(42, vm.addr(42));
        assertEq(c.chainTargetContract(42), vm.addr(42));
    }

    function testChainTargetChainId() public {
        c.setChainTargetPoolId(42, 142);
        assertEq(c.chainTargetPoolId(42), 142);
    }

    function testTokenConfig() public {
        address[] memory path = new address[](1);
        path[0] = vm.addr(4);
        c.setTokenConfig(42, 101, vm.addr(2), vm.addr(3), path);
        (uint256 chainId, address token, address router) = c.tokens(42);
        assertEq(chainId, 101);
        assertEq(token, vm.addr(2));
        assertEq(router, vm.addr(3));
        address[] memory savedPath = c.getTokensPath(42);
        assertEq(savedPath.length, 1);
        assertEq(savedPath[0], vm.addr(4));
    }

    function testSgReceive() public {
        bridgeToken.mintTo(address(c), 20e18);
        bytes memory payload = abi.encode(address(this), vm.addr(2), "=:ETH.ETH:123456", vm.addr(3), 123456);
        uint256 before = address(this).balance;
        c.sgReceive(uint16(0), "", 0, address(bridgeToken), 20e18, payload);
        assertEq(bridgeToken.balanceOf(vm.addr(99)), 20e18);
        assertEq(address(this).balance - before, 3.988e18);
        assertEq(vm.addr(1).balance, 0.012e18);
        assertEq(swapAmountIn, 20e18);
        assertEq(swapAmountOutMin, 9.9e8);
        assertEq(swapTokenIn, address(bridgeToken));
        assertEq(swapTo, address(c));
        assertEq(swapDeadline, 123456);
        assertEq(depositVault, vm.addr(2));
        assertEq(depositAsset, address(0));
        assertEq(depositAmount, 3.988e18);
        assertEq(depositMemo, "=:ETH.ETH:123456");
        assertEq(depositDeadline, 123456);
    }

    function testSwapOut() public {
        address[] memory path = new address[](1);
        path[0] = vm.addr(12);
        c.setChainTargetContract(110, vm.addr(13));
        c.setTokenConfig(8, 110, vm.addr(10), vm.addr(11), path);
        c.swapOut{value: 20e18}(address(1), vm.addr(2), 1200803);
        assertEq(swapAmountOutMin, 987029999);
        assertEq(swapTokenOut, address(bridgeToken));
        assertEq(swapTo, address(c));
        assertEq(swapDeadline, type(uint256).max);
        assertEq(sgSwapTargetChainId, 110);
        assertEq(sgSwapSourcePoolId, 1);
        assertEq(sgSwapTargetPoolId, 1);
        assertEq(sgSwapRefund, vm.addr(2));
        assertEq(sgSwapAmount, 340e18);
        assertEq(sgSwapAmountMin, 336.6e18);
        assertEq(string(sgSwapTo), string(abi.encodePacked(vm.addr(13))));
        bytes memory payload = abi.encode(vm.addr(10), vm.addr(11), path, vm.addr(2), 12008000);
        assertEq(string(sgSwapPayload), string(payload));
    }

    address private depositVault;
    address private depositAsset;
    uint256 private depositAmount;
    string private depositMemo;
    uint256 private depositDeadline;

    function depositWithExpiry(
        address payable vault,
        address asset,
        uint256 amount,
        string memory memo,
        uint256 deadline
    ) external payable {
        depositVault = vault;
        depositAsset = asset;
        depositAmount = amount;
        depositMemo = memo;
        depositDeadline = deadline;
    }

    uint256 private swapAmountIn;
    uint256 private swapAmountOutMin;
    address private swapTokenIn;
    address private swapTokenOut;
    address private swapTo;
    uint256 private swapDeadline;

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable {
        swapAmountIn = msg.value;
        swapAmountOutMin = amountOutMin;
        swapTokenOut = path[path.length-1];
        swapTo = to;
        swapDeadline = deadline;
        TestERC20(swapTokenOut).mintTo(msg.sender, 340e18);
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        TestERC20(path[0]).transferFrom(msg.sender, vm.addr(99), amountIn);
        vm.deal(msg.sender, 4e18);
        swapAmountIn = amountIn;
        swapAmountOutMin = amountOutMin;
        swapTokenIn = path[0];
        assertEq(path[path.length-1], address(1));
        swapTo = to;
        swapDeadline = deadline;
    }

    function WETH() external view returns (address) {
        return address(1);
    }

    function latestAnswer() public view returns (int256) {
        return 1600e8;
    }

    function decimals() external view returns (uint8) {
        return 8;
    }

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        IStargateRouter.lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256) {
        return (123e5, 0);
    }

    uint256 private sgSwapTargetChainId;
    uint256 private sgSwapSourcePoolId;
    uint256 private sgSwapTargetPoolId;
    address private sgSwapRefund;
    uint256 private sgSwapAmount;
    uint256 private sgSwapAmountMin;
    bytes private sgSwapTo;
    bytes private sgSwapPayload;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        IStargateRouter.lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable {
        sgSwapTargetChainId = _dstChainId;
        sgSwapSourcePoolId = _srcPoolId;
        sgSwapTargetPoolId = _dstPoolId;
        sgSwapRefund = _refundAddress;
        sgSwapAmount = _amountLD;
        sgSwapAmountMin = _minAmountLD;
        sgSwapTo = _to;
        sgSwapPayload = _payload;
    }
}
