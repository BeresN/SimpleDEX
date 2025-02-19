// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract LiquidityPool is ERC20{
    using SafeERC20 for IERC20;
    uint256 public totalLiquidity;
    address public immutable tokenA;
    address public immutable tokenB;
    address public tokenAddress;

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

    mapping(address => uint256) public lpTokens;

    constructor(address _tokenA, address _tokenB) 
    ERC20("LiquidityPoolToken", "LPT") {
        tokenA = _tokenA;
        tokenB = _tokenB;
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
        return (tokenA, tokenB);
    }
    

    function addLiquidity(
        uint256 amountA,
        uint256 amountB
    ) external returns (uint256 lpMinted) {
        require(amountA > 0 && amountB > 0, "Must be more than 0");

        IERC20(tokenA).safeTransferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).safeTransferFrom(msg.sender, address(this), amountB);

        if (totalLiquidity == 0) {
            lpMinted = Math.sqrt(amountA * amountB);
        }
        lpMinted = Math.min(amountA, amountB);

        require(lpMinted > 0, "LP amount must be > 0");

        lpTokens[msg.sender] += lpMinted;
        totalLiquidity += lpMinted;

        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB, lpMinted);
    }

    function removeLiquidity(
        uint256 lpAmount
    ) public returns (uint256 amountA, uint256 amountB) {
        require(lpAmount > 0, "Amount must be greater than zero");

        amountA = (lpAmount * reserveA) / totalLiquidity;
        amountB = (lpAmount * reserveB) / totalLiquidity;

        require(amountA > 0 && amountB > 0, "Insufficient liquidity");

        _burn(msg.sender, lpAmount);
        totalLiquidity -= lpAmount;

        reserveA -= amountA;
        reserveB -= amountB;

        IERC20(tokenA).safeTransfer(msg.sender, amountA);
        IERC20(tokenB).safeTransfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB, lpAmount);
    }

} 
