// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract LiquidityPool is ERC20 {
    using SafeERC20 for IERC20;
    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;
    address public immutable exchangeAddress;

    uint256 private reserveA;
    uint256 private reserveB;

    event LiquidityAdded(
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

    constructor(
        address _tokenA,
        address _tokenB,
        address _exchangeAddress
    ) ERC20("LiquidityPoolToken", "LPT") {
        exchangeAddress = _exchangeAddress;
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function getReserves() public view returns (uint256, uint256) {
        return (reserveA, reserveB);
    }

    function updateReserves(uint256 newReserveA, uint256 newReserveB) external {
        require(msg.sender == exchangeAddress, "Unauthorized");
        reserveA = newReserveA;
        reserveB = newReserveB;
    }

    function getTokenAddresses() public view returns (address, address) {
        return (address(tokenA), address(tokenB));
    }

    function addLiquidity(
        uint256 amountA,
        uint256 amountB
    ) external returns (uint256 lpMinted) {
        require(amountA > 0 && amountB > 0, "Must be more than 0");
        uint256 lpTotalSupply = totalSupply();
        IERC20(tokenA).safeTransferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).safeTransferFrom(msg.sender, address(this), amountB);

        if (lpTotalSupply == 0) {
            lpMinted = Math.sqrt(uint256(amountA) * uint256(amountB));
        } else {
            lpMinted = Math.min(
                (amountA * lpTotalSupply) / reserveA,
                (amountB * lpTotalSupply) / reserveB
            );
        }
        require(lpMinted > 0, "LP amount must be > 0");

        _mint(msg.sender, lpMinted);
        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB, lpMinted);
        return (lpMinted);
    }

    function removeLiquidity(uint256 lpTokensAmount) external {
        uint256 amountA;
        uint256 amountB;
        uint256 lpTotalSupply = totalSupply();
        require(lpTokensAmount > 0, "Amount must be greater than zero");

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
}
