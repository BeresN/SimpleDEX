// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LiquidityPool is IERC20, ERC20 {
    address public tokenA;
    address public tokenB;
    address public tokenAddress;

    uint256 reserveA;
    uint256 reserveB;

    mapping(address => uint256) public lpTokens;
    uint256 public totalLiquidity;

    constructor(address token) ERC20("LP eth tokens", "lPTK") {
        require(token != address(0), "null address");
        tokenAddress = token;
    }

    constructor(address _tokenA, address _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    function addLiquidity(
        uint256 amountA,
        uint256 amountB
    ) external returns (uint256 lpMinted) {
        require(amountA > 0 && amountB > 0, "Must be more than 0");

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        if (totalLiquidity == 0) {
            _mint(msg.sender, lpMinted);
        }
    }
}
