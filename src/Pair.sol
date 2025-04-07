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
    uint256 public reserveA;
    uint256 public reserveB;

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

    function getReserves() public view returns (uint256, uint256) {
        return (reserveA, reserveB);
    }
    function updateReserves(uint256 _reserveA, uint256 _reserveB) private {
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
        uint256 _reserveA = reserveA;
        uint256 _reserveB = reserveB;

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

    function swap(
        uint128 amountAOut,
        uint128 amountBOut,
        address to
    ) external nonReentrant {
        require(amountAOut > 0 || amountBOut > 0);
        require(to != address(0));

        uint256 _reserveA = reserveA;
        uint256 _reserveB = reserveB;
        require(amountAOut < _reserveA && amountBOut < _reserveB);
        require(to != address(this), "Swap: INVALID_TO");

        if (amountAOut > 0) {
            IERC20(tokenA).safeTransfer(to, amountAOut);
        }
        if (amountBOut > 0) {
            IERC20(tokenB).safeTransfer(to, amountBOut);
        }

        uint256 balanceA = IERC20(tokenA).balanceOf(address(this));
        uint256 balanceB = IERC20(tokenB).balanceOf(address(this));

        uint256 amountAIn = balanceA > _reserveA - amountAOut
            ? balanceA - (_reserveA - amountAOut)
            : 0;
        uint256 amountBIn = balanceB > _reserveB - amountBOut
            ? balanceB - (_reserveB - amountBOut)
            : 0;
        require(
            amountAIn > 0 || amountBIn > 0,
            "Swap: INSUFFICIENT_INPUT_AMOUNT"
        );

        uint256 balanceAWithFee = (balanceA * 1000) - (amountAIn * 1);
        uint256 balanceBWithFee = (balanceA * 1000) - (amountBIn * 1);
        require(
            balanceAWithFee * balanceBWithFee >=
                _reserveA * _reserveB * (1000 ** 2),
            "Swap: K_INVARIANT_FAILED"
        );
        updateReserves(balanceAWithFee, balanceBWithFee);

        emit Swap(msg.sender, amountAIn, amountBIn, amountAOut, amountBOut, to);
    }
}
