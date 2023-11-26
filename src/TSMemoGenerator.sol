// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TSMemoGenerator {

    // Generic memo for swaps and loans
    // e.g. SWAP:BNB.BNB:bnb108n64knfm38f0mm23nkreqqmpc7rpcw89sqqw5:1231230/2/6:t:30
    function generic(
        string memory action, // SWAP
        string memory asset, // BNB.BNB
        string memory destAddr, // bnb108n64knfm38f0mm23nkreqqmpc7rpcw89sqqw5
        string memory limit, // 1231230/2/6
        string memory affiliate, // t
        string memory fee // 30
    ) public pure returns (string memory) {
        string memory memo = string(
            abi.encodePacked(
                action,
                ":",
                asset,
                ":",
                destAddr,
                ":",
                limit,
                ":",
                affiliate,
                ":",
                fee
            )
        );

        return memo;
    }

    // Memo with explicit parameters for streaming swaps
    // e.g. =:r:oleg:0/3/0:t:0
    function swapStreaming(
        string memory action, // =
        string memory asset, // r
        string memory destAddr, // oleg - thorname supported
        string memory limit, // 0
        string memory interval, // 3
        string memory quantity, // 0 - let the protocol decide how many subswaps
        string memory affiliate, // t
        string memory fee // 0
    ) public pure returns (string memory) {
        string memory memo = string(
            abi.encodePacked(
                action,
                ":",
                asset,
                ":",
                destAddr,
                ":",
                limit,
                "/",
                interval,
                "/",
                quantity,
                ":",
                affiliate,
                ":",
                fee
            )
        );

        return memo;
    }

    // Memo with dex aggregation parameters
    // e.g. =:e:0x31b27d6d447b079b716b889ff438c311e5f14eb4:61738022:t:15:15:302:342498409988635794847100
    function swapDexAgg(
        string memory action, // =
        string memory asset, // e
        string memory destAddr, // 0x31b27d6d447b079b716b889ff438c311e5f14eb4
        string memory limit, // 61738022
        string memory affiliate, // t
        string memory fee, // 15
        string memory aggregator, // 15 - fuzzy matching with last digits from aggregator whitelist
        string memory targetAsset, // 302 - fuzzy matching with last digits from tokens whitelist
        string memory minAmountOut // 342498409988635794847100 - min amount out passed to the aggregator contract, prevents sandwich attacks
    ) public pure returns (string memory) {
        string memory memo = string(
            abi.encodePacked(
                action,
                ":",
                asset,
                ":",
                destAddr,
                ":",
                limit,
                ":",
                affiliate,
                ":",
                fee,
                ":",
                aggregator,
                ":",
                targetAsset,
                ":",
                minAmountOut
            )
        );

        return memo;
    }


    // Memo for savers with affiliate parameters
    // e.g. +:ETH/ETH::t:1
    function savers(
        string memory action, // +
        string memory asset, // ETH/ETH
        string memory basisPoints, // (empty for adds)
        string memory affiliate, // t
        string memory fee // 1
    ) public pure returns (string memory) {
        string memory memo = string(
            abi.encodePacked(action, ":", asset, ":", basisPoints, ":", affiliate, ":", fee)
        );

        return memo;
    }

    // Memo to add dual-sided liquidity
    // e.g. +:ETH.THOR-044:thor1s298k6p4rdn7ncwlkzce8x75zsryu5k45aw33y:t:0
    function addLiquidity(
        string memory asset, // ETH.THOR-044
        string memory pairedAddr, // thor1s298k6p4rdn7ncwlkzce8x75zsryu5k45aw33y
        string memory affiliate, // t
        string memory fee // 0
    ) public pure returns (string memory) {
        string memory memo = string(
            abi.encodePacked("+:", asset, ":", pairedAddr, ":", affiliate, ":", fee)
        );

        return memo;
    }

    // Memo to withdraw dual-sided liquidity
    // e.g. -:ETH.THOR-044:10000:THOR.RUNE
    function withdrawLiquidity(
        string memory asset, // ETH.THOR-044
        string memory basisPoints, // 10000 (100%)
        string memory withdrawAsset // THOR.RUNE
    ) public pure returns (string memory) {
        string memory memo = string(
            abi.encodePacked("-:", asset, ":", basisPoints, ":", withdrawAsset)
        );

        return memo;
    }

    // Function to hash UTF-8 memo
    function hashMemo(string memory memo) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(memo));
    }
}