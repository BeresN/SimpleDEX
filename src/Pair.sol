// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Pair is ERC20 {
    using SafeERC20 for IERC20;
    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;
    uint256 reserveA;
    uint256 reserveB;

    event liquidityAdded(
        address indexed user,
        uint256 amountA,
        uint256 amountB,
        uint256 lpMinted
    );
    event LiquidityRemoved(
        address indexed user,
        uint256 amountA,
        uint256 amountB,
        uint256 lpBurned
    );
    event Swap(
        address indexed sender,
        uint256 amountA,
        uint256 amountB,
        uint256 tokenOut,
        address indexed to
    );

    constructor(
        address _tokenA,
        address _tokenB
    ) ERC20("LiquidityPoolToken", "LPT") {
        require(_tokenA != address(0) && _tokenB != address(0), "Zero address");
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function getReserves() public view returns (uint256, uint256) {
        return (reserveA, reserveB);
    }
    function updateReserves(uint256 newReserveA, uint256 newReserveB) internal {
        reserveA = newReserveA;
        reserveB = newReserveB;
    }

    function addLiquidity(
        uint128 amountA,
        uint128 amountB
    ) external returns (uint256 lpTokensMinted) {
        require(amountA > 0 && amountB > 0, "Must be more than 0");
        uint256 lpTotalSupply = totalSupply();
        IERC20(tokenA).safeTransferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).safeTransferFrom(msg.sender, address(this), amountB);

        if (lpTotalSupply == 0) {
            lpTokensMinted = Math.sqrt(uint256(amountA) * uint256(amountB));
        } else {
            lpTokensMinted = Math.min(
                (amountA * lpTotalSupply) / reserveA,
                (amountB * lpTotalSupply) / reserveB
            );
        }
        require(lpTokensMinted > 0, "LP amount must be > 0");

        _mint(msg.sender, lpTokensMinted);
        reserveA += amountA;
        reserveB += amountB;

        emit liquidityAdded(msg.sender, amountA, amountB, lpTokensMinted);
        return (lpTokensMinted);
    }

    function removeLiquidity(
        uint256 lpTokensAmount
    ) external returns (uint256 amountA, uint256 amountB) {
        require(lpTokensAmount > 0);
        uint256 lpTotalSupply = totalSupply();
        amountA = (lpTokensAmount * reserveA) / lpTotalSupply;
        amountB = (lpTokensAmount * reserveB) / lpTotalSupply;

        require(amountA > 0 && amountB > 0, "Insufficient liquidity");

        _burn(msg.sender, lpTokensAmount);

        reserveA -= amountA;
        reserveB -= amountB;

        IERC20(tokenA).safeTransfer(msg.sender, amountA);
        IERC20(tokenB).safeTransfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB, lpTokensAmount);
    }

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

    function swap(
        uint amountA,
        uint amountB,
        address to
    ) external returns (uint256 tokenOut) {
        require(amountA > 0 || amountB > 0);
        require(to != address(0));
        require(amountA < reserveA || amountB < reserveB);

        if (amountA > 0) {
            tokenOut = getOutputAmountFromSwap(amountA, reserveA, reserveB);
            IERC20(tokenA).safeTransfer(to, amountA);
            updateReserves(reserveA -= amountA, reserveB += amountA);
        }
        if (amountB > 0) {
            tokenOut = getOutputAmountFromSwap(amountA, reserveA, reserveB);
            IERC20(tokenB).safeTransfer(to, amountB);
            updateReserves(reserveB -= amountB, reserveA += amountB);
        }

        emit Swap(msg.sender, amountA, amountB, tokenOut, to);
    }
}
