// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Pair is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;
    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;
    uint128 public reserveA;
    uint128 public reserveB;

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
        uint256 amountAOut,
        uint256 amountBOut,
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

    function getReserves() public view returns (uint128, uint128) {
        return (reserveA, reserveB);
    }
    function updateReserves(uint128 _reserveA, uint128 _reserveB) private {
        reserveA = _reserveA;
        reserveB = _reserveB;
    }

    function addLiquidity(
        uint128 amountA,
        uint128 amountB
    ) external nonReentrant returns (uint256 lpTokensMinted) {
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
        reserveA += amountA;
        reserveB += amountB;
        _mint(msg.sender, lpTokensMinted);

        emit liquidityAdded(msg.sender, amountA, amountB, lpTokensMinted);
        return (lpTokensMinted);
    }

    function removeLiquidity(
        uint256 lpTokensAmount
    ) external nonReentrant returns (uint256 amountA, uint256 amountB) {
        require(lpTokensAmount > 0);
        uint256 lpTotalSupply = totalSupply();
        uint128 _reserveA = reserveA;
        uint128 _reserveB = reserveB;

        // Example safety check
        amountA = (lpTokensAmount * _reserveA) / lpTotalSupply;
        amountB = (lpTokensAmount * _reserveB) / lpTotalSupply;
        require(
            amountA <= type(uint128).max && amountB <= type(uint128).max,
            "Overflow"
        );
        _burn(msg.sender, lpTokensAmount);

        _reserveA -= uint128(amountA);
        _reserveB -= uint128(amountB);

        updateReserves(_reserveA, _reserveB);

        IERC20(tokenA).safeTransfer(msg.sender, amountA);
        IERC20(tokenB).safeTransfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB, lpTokensAmount);
    }

    function IncludeSwapFee(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256 amountOut) {
        require(
            inputReserve > 0 && outputReserve > 0,
            "Reserves must be greater than 0"
        );

        uint256 amountWithFee = inputAmount * 999;

        uint256 numerator = (amountWithFee * outputReserve);
        uint256 denominator = ((inputReserve * 1000) + amountWithFee);

        require(numerator / denominator > 0, "Zero output amount");
        amountOut = numerator / denominator;
        return amountOut;
    }

    function swap(
        uint128 amountA,
        uint128 amountB,
        address to
    ) external nonReentrant {
        require(amountA > 0 || amountB > 0);
        require(to != address(0));

        uint128 _reserveA = reserveA;
        uint128 _reserveB = reserveB;
        require(amountA < reserveA || amountB < reserveB);
        uint256 amountAOut;
        uint256 amountBOut;

        if (amountA > 0) {
            amountAOut = IncludeSwapFee(amountA, _reserveA, _reserveB);
            updateReserves(
                _reserveA -= amountA,
                _reserveB += uint128(amountAOut)
            );
            IERC20(tokenA).safeTransfer(to, amountAOut);
        }
        if (amountB > 0) {
            amountBOut = IncludeSwapFee(amountB, _reserveA, reserveB);
            updateReserves(
                _reserveB -= amountB,
                _reserveA += uint128(amountBOut)
            );
            IERC20(tokenB).safeTransfer(to, amountBOut);
        }

        emit Swap(msg.sender, amountA, amountB, amountAOut, amountBOut, to);
    }
}
