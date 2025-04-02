// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Pair.sol";

contract Factory is Ownable {
    constructor(address initialOwner) Ownable(initialOwner) {}

    function newPair(
        address tokenA,
        address tokenB
    ) external onlyOwner returns (address pair) {}
}
