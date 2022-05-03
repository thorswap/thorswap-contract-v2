// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import { DSTest } from "../../lib/DSTest.sol";
import { TestERC20 } from "./TestERC20.sol";
import { IERC20 } from "../interfaces/IERC20.sol";
import { RewardsForwarder } from "../RewardsForwarder.sol";

contract vTHORTest is DSTest {
    TestERC20 thor;
    RewardsForwarder rf;

    function setUp() public {
        thor = new TestERC20();
        thor.mintTo(address(this), 100e18);
        rf = new RewardsForwarder(5, address(thor), vm.addr(2), vm.addr(1));
    }

    function testSendRewards() public {
        try rf.sendRewards() {
            revert("did not error");
        } catch Error(string memory r) {
            assertEq(string(r), "Not operator");
        }

        thor.mintTo(address(rf), 100e18);
        vm.startPrank(vm.addr(1));
        uint256 newBlock = block.number + 10;
        vm.roll(newBlock);
        uint256 bef = thor.balanceOf(address(vm.addr(2)));
        rf.sendRewards();
        uint256 aft = thor.balanceOf(address(vm.addr(2)));
        assertEq(aft-bef, 50);
        assertEq(rf.lastBlock(), newBlock);
    }

    function testSetLastBlock() public {
        rf.setLastBlock(123);
        assertEq(rf.lastBlock(), 123);
    }

    function testSetRewardPerBlock() public {
        rf.setRewardPerBlock(567);
        assertEq(rf.rewardPerBlock(), 567);
    }

    function testSetAddresses() public {
        rf.setAddresses(vm.addr(11), vm.addr(12), vm.addr(13));
        assertEq(rf.token(), vm.addr(11));
        assertEq(rf.target(), vm.addr(12));
        assertEq(rf.operator(), vm.addr(13));
    }

    function testWithdrawTokens() public {
        thor.transfer(address(rf), 1e18);
        uint256 bef = thor.balanceOf(address(this));
        rf.withdrawTokens(1e18);
        uint256 aft = thor.balanceOf(address(this));
        assertEq(aft-bef, 1e18);

        vm.startPrank(vm.addr(1));
        try rf.withdrawTokens(123) {
            revert("did not error");
        } catch Error(string memory r) {
            assertEq(string(r), "Unauthorized");
        }
    }
}
