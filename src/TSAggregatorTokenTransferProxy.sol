// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import { SafeTransferLib } from "../lib/SafeTransferLib.sol";
import { Owners } from "./Owners.sol";

contract TSAggregatorTokenTransferProxy is Owners {
    using SafeTransferLib for address;

    mapping(address => bool) public authorized;

    event AuthorizedSet(address indexed owner, bool active);

    constructor() {
        _setOwner(msg.sender, true);
    }

    modifier isAuthorized() {
        require(authorized[msg.sender], "Unauthorized");
        _;
    }

    function _setAuthorized(address user, bool active) internal {
      authorized[user] = active;
      emit AuthorizedSet(user, active);
    }

    function setAuthorized(address user, bool active) public isOwner {
      _setAuthorized(user, active);
    }

    function transferTokens(address token, address from, address to, uint256 amount) external isAuthorized {
        require(from == tx.origin || _isContract(from), "Invalid from address");
        token.safeTransferFrom(from, to, amount);
    }

    function _isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}
