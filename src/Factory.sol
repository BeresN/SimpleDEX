// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./LiquidityPool.sol";
import "./Exchange.sol";

contract Factory is Ownable {
    mapping(address => mapping(address => address)) public getPair;
    mapping(address => address) public getExchange; // Maps pool address to exchange address
    //array to store all pairs
    address[] public allTokenPairs;

    event PairCreated(
        address token0,
        address token1,
        address pool,
        address exchange,
        uint totalPairs
    );

    event OwnerChanged(address newOwner);

    constructor(address initialOwner) Ownable(initialOwner) {}

    function allPairsLength() external view returns (uint) {
        return allTokenPairs.length;
    }

    function CreateNewPair(
        address tokenA,
        address tokenB
    ) external onlyOwner returns (address pool) {
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

        // Create LiquidityPool with placeholder exchange address
        LiquidityPool liquidityPool = new LiquidityPool(token0, token1, address(0));
        pool = address(liquidityPool);

        // Create Exchange with the pool
        Exchange exchange = new Exchange(pool, owner());

        // Set the exchange address in the pool
        liquidityPool.setExchangeAddress(address(exchange));

        // Store pool and exchange addresses
        getPair[token0][token1] = pool;
        getPair[token1][token0] = pool;
        getExchange[pool] = address(exchange);
        allTokenPairs.push(pool);

        emit PairCreated(token0, token1, pool, address(exchange), allTokenPairs.length);
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

    function OwnerAddressChange(
        address newOwner
    ) external returns (address owner) {
        require(newOwner != address(0), "CANNOT BE ADDRESS 0!");
        owner = newOwner;

        emit OwnerChanged(owner);
    }
}
