// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library LinearRate
{
    function linearRate(
        uint256 x,
        uint256 xHigh,
        uint256 xLow,
        uint256 yHigh,
        uint256 yLow
    ) internal pure returns (uint256)
    {
        require(x <= xHigh && x >= xLow, "x out of range");
        if (xHigh == xLow) return yLow;

        // y = yHigh + (xHigh - x) * (yLow - yHigh) / (xHigh - xLow)
        return yHigh + ((xHigh - x) * (yLow - yHigh)) / (xHigh - xLow);
    }
}