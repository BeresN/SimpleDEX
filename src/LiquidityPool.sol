// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LiquidityPool is ERC20 {
    address public token;
    uint256 public totalLiquidity;
    mapping(address => uint256) public liquidity;

    constructor(address _token) ERC20("Liquidity Pool Token", "LP") {
        require(_token != address(0), "Invalid token address");
        token = _token;
    }

    function addLiquidity(uint256 tokenAmount) public payable {
        require(msg.value > 0 && tokenAmount > 0, "Invalid amounts");
        ERC20(token).transferFrom(msg.sender, address(this), tokenAmount);
        liquidity[msg.sender] += msg.value;
        totalLiquidity += msg.value;
    }

    function removeLiquidity(uint256 amount) public {
        require(liquidity[msg.sender] >= amount, "Insufficient liquidity");
        uint256 ethAmount = (address(this).balance * amount) / totalLiquidity;
        uint256 tokenAmount = (ERC20(token).balanceOf(address(this)) * amount) /
            totalLiquidity;

        liquidity[msg.sender] -= amount;
        totalLiquidity -= amount;

        payable(msg.sender).transfer(ethAmount);
        ERC20(token).transfer(msg.sender, tokenAmount);
    }

    function getReserve() public view returns (uint256) {
        return ERC20(token).balanceOf(address(this));
    }
}
