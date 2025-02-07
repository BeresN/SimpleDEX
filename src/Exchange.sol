// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./LiquidityPool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {
    address public tokenAddress;

    constructor(address token) ERC20("LP eth tokens", "lPTK") {
        require(token != address(0), "null address");
        tokenAddress = token;
    }

    function getReserves() public view returns(uint256) {
        return ERC20(tokenAddresss).balanceOf(address(this);)
    }

    function addLiquidity(
        uint256 tokenAmount
    ) public payable returns(uint256){
        uint256 lpTokensToMint;
        uint256 ethBalance = address(this).balance;
        uint256 tokenBalance = getReserves();

        ERC20 token = ERC20(tokenAddress);
        
        lpTokensToMint = ethBalance;
    }
}
