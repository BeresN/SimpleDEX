// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "./LiquidityPool.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";



contract Exchange is ReentrancyGuard{
    using SafeERC20 for IERC20;
    LiquidityPool public pool;
    address public liquidityPoolAddress;
    address public tokenA;
    address public tokenB;
    address public exchangeAddress;


    constructor(address _liquidityPool) {
        pool = LiquidityPool(_liquidityPool);
        (tokenA, tokenB) = pool.getTokenAddresses();
        exchangeAddress = msg.sender;
        require(tokenA != address(0) && tokenB != address(0), "Invalid token addresses");
    }

    function setExchangeAddress(address _exchangeAddress) external {
        require(exchangeAddress == address(0), "Exchange address already set");
        exchangeAddress = _exchangeAddress;
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

        uint256 inputAmountWithFee = inputAmount * 99;

        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;

        return numerator / denominator;
    }

    function tokenToEthSwap(
        uint256 tokensAmount
    )
        external returns(uint256 ethToReceive) {
        (uint256 reserveA, uint256 reserveB) = pool.getReserves();

        ethToReceive = (tokensAmount * reserveB) / (reserveA + tokensAmount);

        IERC20(pool.tokenA()).safeTransferFrom(msg.sender, address(pool), tokensAmount);
        IERC20(pool.tokenB()).safeTransferFrom(msg.sender, address(pool), ethToReceive);



        }
    
}
