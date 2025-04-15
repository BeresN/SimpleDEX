// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

interface iPair {
    function getReserves() external view returns (uint256 lpTokenMinted);
    function addLiquidity(
        uint256 amountA,
        uint256 amountB
    ) external returns (uint256);

    function removeLiquidity(
        uint256 lpTokensAmount
    ) external returns (uint256 amountABack, uint256 amountBBack);

    function swap(uint128 amountA, uint128 amountB, address to) external;
}
