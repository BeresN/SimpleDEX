pragma solidity ^0.8.28;

interface iMyDexPair {
    function getReserves() external view returns (uint256, uint256);
    function addLiquidity(
        uint256 amountA,
        uint256 amountB
    ) external returns (uint256);
    function removeLiquidity(
        uint256 amountA,
        uint256 amountB
    ) external returns (uint256);
    function swap(
        uint amountA,
        uint amountB,
        address to,
        bytes calldata data
    ) external;
}
