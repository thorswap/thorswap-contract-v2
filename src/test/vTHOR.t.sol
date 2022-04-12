// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import { DSTest } from "../../lib/DSTest.sol";
import { TestERC20 } from "./TestERC20.sol";
import { IERC20 } from "../interfaces/IERC20.sol";
import { vTHOR } from "../vTHOR.sol";

contract vTHORTest is DSTest {
    TestERC20 thor;
    vTHOR vthor;

    function setUp() public {
        thor = new TestERC20();
        thor.mintTo(address(this), 100e18);
        vthor = new vTHOR(IERC20(address(thor)));
    }

    function testDeposit() public {
        thor.approve(address(vthor), 30e18);

        vthor.deposit(10e18, address(this));
        assertEq(thor.balanceOf(address(this)), 90e18);
        assertEq(vthor.balanceOf(address(this)), 10e18);
        assertEq(vthor.totalSupply(), 10e18);

        vthor.deposit(20e18, address(this));
        assertEq(vthor.balanceOf(address(this)), 30e18);
        assertEq(vthor.totalSupply(), 30e18);
    }

    function testWithdraw() public {
        thor.approve(address(vthor), 30e18);
        vthor.deposit(10e18, address(this));
        vthor.redeem(5e18, address(this), address(this));
        assertEq(thor.balanceOf(address(this)), 95e18);
        assertEq(vthor.balanceOf(address(this)), 5e18);
        assertEq(vthor.totalSupply(), 5e18);
    }

    function testScaling() public {
        thor.approve(address(vthor), 10e18);
        thor.transfer(address(vthor), 30e18);
        vthor.deposit(10e18, address(this));

        uint256 balanceBefore = thor.balanceOf(address(this));
        vthor.redeem(1e18, address(this), address(this));
        uint256 balanceAfter = thor.balanceOf(address(this));
        assertEq(balanceAfter - balanceBefore, 4e18);
        assertEq(vthor.balanceOf(address(this)), 9e18);
        assertEq(vthor.totalSupply(), 9e18);
    }
}
