// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Token.sol";
import "../src/LiquidityPool.sol";
import "../src/Exchange.sol";

contract ExchangeTest is Test {
    Token public tokenA;
    Token public tokenB;
    LiquidityPool public pool;
    Exchange public exchange;

    address public user1 = address(0x1);
    address public user2 = address(0x2);

    uint256 constant INITIAL_SUPPLY = 100000 * 10 ** 18;
    uint256 constant LIQUIDITY_AMOUNT = 1000 * 10 ** 18;

    function setUp() public {
        // Deploy tokens
    tokenA = new Token();
    tokenB = new Token();

    // Deploy exchange and pool with correct linkage
    exchange = new Exchange(address(0), address(this)); // Temporary
    pool = new LiquidityPool(address(tokenA), address(tokenB), address(exchange));
    // Update exchange to point to pool
    exchange = new Exchange(address(pool), address(this));

    // Distribute tokens to users and contracts
    tokenA.transfer(user1, INITIAL_SUPPLY / 2);
    tokenB.transfer(user1, INITIAL_SUPPLY / 2);
    tokenA.transfer(user2, INITIAL_SUPPLY / 2);
    tokenB.transfer(user2, INITIAL_SUPPLY / 2);
    tokenA.transfer(address(exchange), LIQUIDITY_AMOUNT);
    
    // Add initial liquidity to pool for swaps
    vm.startPrank(address(this));
    tokenA.approve(address(pool), LIQUIDITY_AMOUNT);
    tokenB.approve(address(pool), LIQUIDITY_AMOUNT);
    pool.addLiquidity(LIQUIDITY_AMOUNT, LIQUIDITY_AMOUNT);
    vm.stopPrank();

    // Set up prank for approvals
    vm.startPrank(user1);
    tokenA.approve(address(pool), type(uint256).max);
    tokenB.approve(address(pool), type(uint256).max);
    tokenA.approve(address(exchange), type(uint256).max);
    tokenB.approve(address(exchange), type(uint256).max);
    vm.stopPrank();

    vm.startPrank(user2);
    tokenA.approve(address(pool), type(uint256).max);
    tokenB.approve(address(pool), type(uint256).max);
    tokenA.approve(address(exchange), type(uint256).max);
    tokenB.approve(address(exchange), type(uint256).max);
    vm.stopPrank();
    }

    function testInitialDeployment() public {
        assertEq(tokenA.balanceOf(address(this)), 0);
        assertEq(tokenA.balanceOf(user1), INITIAL_SUPPLY / 2);
        assertEq(tokenB.balanceOf(user2), INITIAL_SUPPLY / 2);
        assertEq(pool.tokenA(), address(tokenA));
        assertEq(pool.tokenB(), address(tokenB));
        assertEq(exchange.tokenA(), address(tokenA));
        assertEq(exchange.tokenB(), address(tokenB));
    }

    function testAddLiquidity() public {
        vm.startPrank(user1);
        
        uint256 amountA = LIQUIDITY_AMOUNT;
        uint256 amountB = LIQUIDITY_AMOUNT;
        
        pool.addLiquidity(amountA, amountB);
        
        (uint256 reserveA, uint256 reserveB) = pool.getReserves();
        assertEq(reserveA, amountA);
        assertEq(reserveB, amountB);
        assertEq(pool.balanceOf(user1), Math.sqrt(amountA * amountB));
        
        vm.stopPrank();
    }

    function testRemoveLiquidity() public {
        vm.startPrank(user1);
        
        uint256 amountA = LIQUIDITY_AMOUNT;
        uint256 amountB = LIQUIDITY_AMOUNT;
        uint256 lpMinted = pool.addLiquidity(amountA, amountB);
        
        uint256 initialTokenA = tokenA.balanceOf(user1);
        uint256 initialTokenB = tokenB.balanceOf(user1);
        
        pool.removeLiquidity(lpMinted);
        
        assertEq(tokenA.balanceOf(user1), initialTokenA + amountA);
        assertEq(tokenB.balanceOf(user1), initialTokenB + amountB);
        assertEq(pool.balanceOf(user1), 0);
        
        (uint256 reserveA, uint256 reserveB) = pool.getReserves();
        assertEq(reserveA, 0);
        assertEq(reserveB, 0);
        
        vm.stopPrank();
    }

    function testSwapTokenAToB() public {
        vm.startPrank(user1);
        
        // Add initial liquidity
        pool.addLiquidity(LIQUIDITY_AMOUNT, LIQUIDITY_AMOUNT);
        
        uint256 swapAmount = 100 * 10 ** 18;
        uint256 initialTokenB = tokenB.balanceOf(user1);
        
        uint256 expectedOut = exchange.getOutputAmountFromSwap(
            swapAmount,
            LIQUIDITY_AMOUNT,
            LIQUIDITY_AMOUNT
        );
        
        uint256 received = exchange.swapTokenAToB(swapAmount);
        
        assertEq(received, expectedOut);
        assertEq(tokenB.balanceOf(user1), initialTokenB + received);
        assertEq(tokenA.balanceOf(address(pool)), LIQUIDITY_AMOUNT + swapAmount);
        
        (uint256 reserveA, uint256 reserveB) = pool.getReserves();
        assertEq(reserveA, LIQUIDITY_AMOUNT + swapAmount);
        assertEq(reserveB, LIQUIDITY_AMOUNT - received);
        
        vm.stopPrank();
    }

    function testSwapTokenBToA() public {
        vm.startPrank(user1);
        
        // Add initial liquidity
        pool.addLiquidity(LIQUIDITY_AMOUNT, LIQUIDITY_AMOUNT);
        
        uint256 swapAmount = 100 * 10 ** 18;
        uint256 initialTokenA = tokenA.balanceOf(user1);
        
        uint256 expectedOut = exchange.getOutputAmountFromSwap(
            swapAmount,
            LIQUIDITY_AMOUNT,
            LIQUIDITY_AMOUNT
        );
        
        uint256 received = exchange.swapTokenBToA(swapAmount);
        
        assertEq(received, expectedOut);
        assertEq(tokenA.balanceOf(user1), initialTokenA + received);
        assertEq(tokenB.balanceOf(address(pool)), LIQUIDITY_AMOUNT + swapAmount);
        
        (uint256 reserveA, uint256 reserveB) = pool.getReserves();
        assertEq(reserveA, LIQUIDITY_AMOUNT - received);
        assertEq(reserveB, LIQUIDITY_AMOUNT + swapAmount);
        
        vm.stopPrank();
    }

    function testFailSwapInsufficientLiquidity() public {
        vm.startPrank(user1);
        
        // Try to swap without liquidity
        vm.expectRevert("Insufficient TokenB");
        exchange.swapTokenAToB(100 * 10 ** 18);
        
        vm.stopPrank();
    }

    function testOwnerTransfer() public {
        uint256 amount = 5 ether;
        // Add liquidity first
        vm.prank(user1);
        pool.addLiquidity(LIQUIDITY_AMOUNT, LIQUIDITY_AMOUNT);
        
        uint256 initialBalance = tokenA.balanceOf(user2);
        exchange.transferTokens(address(tokenA), user2, amount);
        
        assertEq(tokenA.balanceOf(user2), initialBalance + amount);
    }

    function testFailUnauthorizedTransfer() public {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        exchange.transferTokens(address(tokenA), user2, 100 * 10 ** 18);
    }
}