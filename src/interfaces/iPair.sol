// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

interface iPair {
    function getReserves() external view returns (uint128, uint128);
    function addLiquidity(
        uint256 amountA,
        uint256 amountB
    ) external returns (uint256);

    function removeLiquidity(uint256 lpTokensAmount) external returns (uint256);

    function swap(
        uint128 amountA,
        uint128 amountB,
        address to,
        bytes calldata data
    ) external;
}
