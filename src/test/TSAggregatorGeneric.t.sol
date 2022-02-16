// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import { DSTest } from "../../lib/DSTest.sol";
import { TestERC20 } from "./TestERC20.sol";
import { TSAggregatorGeneric } from "../TSAggregatorGeneric.sol";

contract TSAggregatorGenericTest is DSTest {
    bool swapCalled;
    address tcRouterVault;
    address tcRouterToken;
    uint tcRouterAmount;
    string tcRouterMemo;
    uint tcRouterDeadline;

    TestERC20 token;
    TSAggregatorGeneric agg;

    function setUp() public {
        token = new TestERC20();
        agg = new TSAggregatorGeneric(500, vm.addr(2));
    }

    function mockSwap() public {
        swapCalled = true;
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
        bytes memory data = new bytes(4);
        bytes4 dataRaw = bytes4(keccak256("mockSwap()"));
        for (uint8 i = 0; i < 4; i++) {
          data[i] = dataRaw[i];
        }
        agg.swapIn(
            address(this),
            vm.addr(1),
            "SWAP:...",
            address(token),
            50e18,
            address(this),
            data,
            1234
        );
        assert(swapCalled);
        assertEq(tcRouterVault, vm.addr(1));
        assertEq(tcRouterMemo, "SWAP:...");
        assertEq(tcRouterToken, address(0));
        assertEq(tcRouterAmount, 19e17);
        assertEq(tcRouterDeadline, 1234);
    }
}
