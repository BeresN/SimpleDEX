// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "./LiquidityPool.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



contract Exchange is Ownable, ReentrancyGuard{
    using SafeERC20 for IERC20;
    LiquidityPool public immutable pool;
    address public immutable tokenA;
    address public immutable tokenB;


    event Swap(address indexed user, uint256 amountIn, uint256 amountOut, bool isTokenToEth);

    constructor(address _liquidityPool, address initialOwner) Ownable(initialOwner) {
        pool = LiquidityPool(_liquidityPool);
        (tokenA, tokenB) = pool.getTokenAddresses();
        require(tokenA != address(0) && tokenB != address(0), "Invalid token addresses");
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

        uint256 inputAmountWithFee = inputAmount * 99 / 100;

        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;

        return numerator / denominator;
    }

    function tokenToEthSwap(
        uint256 tokenAmount
    )
        public payable nonReentrant returns(uint256 ethToReceive) {
        (uint256 reserveA, uint256 reserveB) = pool.getReserves();

        ethToReceive = getOutputAmountFromSwap(
            tokenAmount,
            reserveA,
            reserveB
        );
        require(reserveB >= ethToReceive);

        IERC20(tokenA).safeTransferFrom(msg.sender, address(pool), tokenAmount);
        pool.updateReserves(reserveA + tokenAmount, reserveB - ethToReceive);
        pool.swapTokenToEth(msg.sender, tokenAmount, ethToReceive);
        emit Swap(msg.sender, tokenAmount, ethToReceive, true);
        return ethToReceive;

        
    }

    function ethToTokens()
        public payable nonReentrant returns(uint256 tokenToReceive) {
        (uint256 reserveA, uint256 reserveB) = pool.getReserves();

        require(msg.value > 0, "Invalid amount of ETH");
        
        tokenToReceive = getOutputAmountFromSwap(
            msg.value,
            reserveB,
            reserveA
        );
        require(reserveA >= tokenToReceive);

        payable(address(pool)).transfer(msg.value);
        pool.updateReserves(reserveA - tokenToReceive, reserveB + msg.value);
        IERC20(tokenA).safeTransfer(msg.sender, tokenToReceive);
        emit Swap(msg.sender, msg.value ,tokenToReceive, false);
        return tokenToReceive;
    }

    function transferTokens(address token, address to, uint256 amount) external onlyOwner{
        require(token == tokenA|| token == tokenB, "Invalid token");
        IERC20(token).safeTransfer(to, amount);
    }

    receive() external payable {}

    
}
