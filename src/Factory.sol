// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Pair.sol";

contract Factory is Ownable {
    mapping(address => mapping(address => address)) public getPair;
    //array to store all pairs
    address[] public allTokenPairs;

    event PairCreated(
        address token0,
        address token1,
        address pair,
        uint totalPairs
    );

    constructor(address initialOwner) Ownable(initialOwner) {}

    function allPairsLength() external view returns (uint) {
        return allTokenPairs.length;
    }

    function CreateNewPair(
        address tokenA,
        address tokenB
    ) external onlyOwner returns (address pair) {
        require(tokenA != tokenB, "SAME TOKENS!");
        //ensuring right order in array
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(
            token0 != address(0) && token1 != address(0),
            "CANNOT BE ADDRESS 0!"
        );

        require(getPair[token0][token1] == address(0), "PAIR ALREADY EXISTS");

        //passing address to constructor
        Pair newPair = new Pair(token0, token1);
        pair = address(newPair);

        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allTokenPairs.push(pair);

        emit PairCreated(token0, token1, pair, allTokenPairs.length);
    }

    function getPairAddress(
        address tokenA,
        address tokenB
    ) external view returns (address pair) {
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);

        pair = getPair[token0][token1];
    }
}
