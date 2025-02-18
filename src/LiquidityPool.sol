// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";


contract LiquidityPool is IERC20, ERC20 {
    address public tokenA;
    address public tokenB;
    address public tokenAddress;

    uint256 reserveA;
    uint256 reserveB;

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
    uint256 public totalLiquidity;

    constructor(address _tokenA, address _tokenB) ERC20("LP Tokens", "LPTK") {
        require(
            _tokenA != address(0) && _tokenB != address(0),
            "Invalid token address"
        );
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    function getReserves() public view returns (uint256, uint256) {
        return (reserveA, reserveB);
    }

    function addLiquidity(
        uint256 amountA,
        uint256 amountB
    ) external returns (uint256 lpMinted) {
        require(amountA > 0 && amountB > 0, "Must be more than 0");

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

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

        _burn(msg.sender, lpAmount);

        reserveA -= amountA;
        reserveB -= amountB;

        ERC20(tokenA).transfer(msg.sender, amountA);
        ERC20(tokenB).transfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB, lpAmount);
    }

    //function to find minimum between a and b
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}
