// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

interface iFactor {
    function createNewPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairsLength() external view returns (uint);
}
