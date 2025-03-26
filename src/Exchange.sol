// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./LiquidityPool.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Exchange is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    LiquidityPool public immutable pool;
    address public immutable tokenA;
    address public immutable tokenB;

    event Swap(
        address indexed user,
        uint256 amountIn,
        uint256 amountOut,
        bool isTokenToEth
    );

    constructor(
        address _liquidityPool,
        address initialOwner
    ) Ownable(initialOwner) {
        pool = LiquidityPool(_liquidityPool);
        (tokenA, tokenB) = pool.getTokenAddresses();
        require(
            tokenA != address(0) && tokenB != address(0),
            "Invalid token addresses"
        );
    }

    // getOutputAmountFromSwap calculates the amount of output
    // tokens to be received based on xy = (x + dx)(y - dy)
    function getOutputAmountFromSwap(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        require(
            inputReserve > 0 && outputReserve > 0,
            "Reserves must be greater than 0"
        );

        uint256 inputAmountWithFee = (inputAmount * 99) / 100;

        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;

        require(numerator / denominator > 0, "Zero output amount");
        return numerator / denominator;
    }

    function swapTokenAToB(
        uint256 tokenAAmount
    ) public nonReentrant returns (uint256 tokenBAmount) {
        (uint256 reserveA, uint256 reserveB) = pool.getReserves();
        tokenBAmount = getOutputAmountFromSwap(
            tokenAAmount,
            reserveA,
            reserveB
        );
        require(reserveB >= tokenBAmount, "Insufficient TokenB");
        IERC20(tokenA).safeTransferFrom(
            msg.sender,
            address(pool),
            tokenAAmount
        );
        pool.updateReserves(reserveA + tokenAAmount, reserveB - tokenBAmount);
        IERC20(tokenB).safeTransferFrom(
            address(pool),
            msg.sender,
            tokenBAmount
        ); // Requires pool approval
        emit Swap(msg.sender, tokenAAmount, tokenBAmount, true);
        return tokenBAmount;
    }

    function swapTokenBToA(
        uint256 tokenBAmount
    ) public nonReentrant returns (uint256 tokenAAmount) {
        (uint256 reserveA, uint256 reserveB) = pool.getReserves();
        tokenAAmount = getOutputAmountFromSwap(
            tokenBAmount,
            reserveB,
            reserveA
        );
        require(reserveA >= tokenAAmount, "Insufficient TokenA");
        IERC20(tokenB).safeTransferFrom(
            msg.sender,
            address(pool),
            tokenBAmount
        );
        pool.updateReserves(reserveA - tokenAAmount, reserveB + tokenBAmount);
        IERC20(tokenA).safeTransferFrom(
            address(pool),
            msg.sender,
            tokenAAmount
        ); // Requires pool approval
        emit Swap(msg.sender, tokenBAmount, tokenAAmount, false);
        return tokenAAmount;
    }

    function transferTokens(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        require(token == tokenA || token == tokenB, "Invalid token");
        IERC20(token).safeTransfer(to, amount);
    }
}
