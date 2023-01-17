// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import { DSTest } from "../../lib/DSTest.sol";
import { TestERC20 } from "./TestERC20.sol";
import { TSSwapGeneric } from "../TSSwapGeneric.sol";
import { TSAggregatorTokenTransferProxy } from "../TSAggregatorTokenTransferProxy.sol";

contract TSSwapGenericTest is DSTest {
    bool swapCalled;

    TestERC20 tokenIn;
    TestERC20 tokenOut;
    TSAggregatorTokenTransferProxy ttp;
    TSSwapGeneric sg;

    function setUp() public {
        tokenIn = new TestERC20();
        tokenOut = new TestERC20();
        ttp = new TSAggregatorTokenTransferProxy();
        sg = new TSSwapGeneric(address(ttp));
        ttp.setOwner(address(sg), true);
        sg.setFee(500, vm.addr(1));
    }

    function mockSwap() public {
        swapCalled = true;
    }

    function testSwapIn() public {
        tokenIn.mintTo(address(this), 50e18);
        tokenIn.approve(address(ttp), 50e18);

        bytes memory data = new bytes(4);
        bytes4 dataRaw = bytes4(keccak256("mockSwap()"));
        for (uint8 i = 0; i < 4; i++) {
            data[i] = dataRaw[i];
        }

        uint256[] memory ps = new uint256[](1);
        ps[0] = 25;
        address[] memory rs = new address[](1);
        rs[0] = vm.addr(2);

        try sg.swap(
            address(tokenIn),
            address(tokenOut),
            vm.addr(3),
            50e18,
            address(this),
            data,
            abi.encode(ps, rs)
        ) {
            revert("did not error");
        } catch Error(string memory r) {
            assertEq(string(r), "no amount out");
        }

        tokenOut.mintTo(address(sg), 2.572e18);
        sg.swap(
            address(tokenIn),
            address(tokenOut),
            vm.addr(3),
            50e18,
            address(this),
            data,
            abi.encode(ps, rs)
        );
        assert(swapCalled);
        assertEq(tokenOut.balanceOf(vm.addr(1)), 0.1286e18);
        assertEq(tokenOut.balanceOf(vm.addr(2)), 0.00643e18);
        assertEq(tokenOut.balanceOf(vm.addr(3)), 2.43697e18);
    }
}
