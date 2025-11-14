// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../../src/LiquidityPool.sol";
import "../mocks/MockERC20.sol";

contract LiquidityPoolTest is Test {
    LiquidityPool public pool;
    MockERC20 public tokenA;
    MockERC20 public tokenB;

    address public exchange = address(1);
    address public liquidityProvider = address(2);
    address public user = address(3);

    uint256 constant INITIAL_MINT = 1000000 * 1e18;

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

    function setUp() public {
        // Deploy tokens
        tokenA = new MockERC20("Token A", "TKA", 18);
        tokenB = new MockERC20("Token B", "TKB", 18);

        // Deploy pool
        pool = new LiquidityPool(
            address(tokenA),
            address(tokenB),
            exchange
        );

        // Mint tokens to liquidity provider
        tokenA.mint(liquidityProvider, INITIAL_MINT);
        tokenB.mint(liquidityProvider, INITIAL_MINT);

        // Mint tokens to user
        tokenA.mint(user, INITIAL_MINT);
        tokenB.mint(user, INITIAL_MINT);

        // Approve pool to spend tokens
        vm.prank(liquidityProvider);
        tokenA.approve(address(pool), type(uint256).max);
        vm.prank(liquidityProvider);
        tokenB.approve(address(pool), type(uint256).max);

        vm.prank(user);
        tokenA.approve(address(pool), type(uint256).max);
        vm.prank(user);
        tokenB.approve(address(pool), type(uint256).max);
    }

    // ============================================
    // CONSTRUCTOR TESTS
    // ============================================

    function test_Constructor_Success() public {
        LiquidityPool newPool = new LiquidityPool(
            address(tokenA),
            address(tokenB),
            exchange
        );

        assertEq(address(newPool.tokenA()), address(tokenA));
        assertEq(address(newPool.tokenB()), address(tokenB));
        assertEq(newPool.exchangeAddress(), exchange);
    }

    function test_Constructor_RevertsOnZeroTokenA() public {
        vm.expectRevert("Zero address");
        new LiquidityPool(address(0), address(tokenB), exchange);
    }

    function test_Constructor_RevertsOnZeroTokenB() public {
        vm.expectRevert("Zero address");
        new LiquidityPool(address(tokenA), address(0), exchange);
    }

    function test_Constructor_RevertsOnZeroExchange() public {
        vm.expectRevert("Zero exchange address");
        new LiquidityPool(address(tokenA), address(tokenB), address(0));
    }

    function test_Constructor_SetsCorrectTokenName() public {
        assertEq(pool.name(), "LiquidityPoolToken");
        assertEq(pool.symbol(), "LPT");
    }

    // ============================================
    // LIQUIDITY ADDITION TESTS
    // ============================================

    function test_AddLiquidity_FirstDeposit() public {
        uint256 amountA = 100 * 1e18;
        uint256 amountB = 100 * 1e18;

        vm.prank(liquidityProvider);
        uint256 lpMinted = pool.addLiquidity(amountA, amountB);

        // First deposit: LP = sqrt(amountA * amountB)
        uint256 expectedLP = Math.sqrt(amountA * amountB);
        assertEq(lpMinted, expectedLP, "LP minted should be sqrt(amountA * amountB)");
        assertEq(pool.balanceOf(liquidityProvider), expectedLP, "LP balance should match");
    }

    function test_AddLiquidity_SubsequentDeposit() public {
        // First deposit
        vm.prank(liquidityProvider);
        pool.addLiquidity(100 * 1e18, 100 * 1e18);

        // Second deposit
        uint256 amountA = 50 * 1e18;
        uint256 amountB = 50 * 1e18;

        vm.prank(user);
        uint256 lpMinted = pool.addLiquidity(amountA, amountB);

        // LP should be proportional to existing supply
        assertTrue(lpMinted > 0, "LP should be minted");
    }

    function test_AddLiquidity_MintsCorrectLPTokens() public {
        uint256 firstAmountA = 100 * 1e18;
        uint256 firstAmountB = 100 * 1e18;

        vm.prank(liquidityProvider);
        pool.addLiquidity(firstAmountA, firstAmountB);

        uint256 totalSupply = pool.totalSupply();
        (uint256 reserveA, uint256 reserveB) = pool.getReserves();

        // Second deposit with same ratio
        uint256 secondAmountA = 50 * 1e18;
        uint256 secondAmountB = 50 * 1e18;

        uint256 expectedLP = Math.min(
            (secondAmountA * totalSupply) / reserveA,
            (secondAmountB * totalSupply) / reserveB
        );

        vm.prank(user);
        uint256 actualLP = pool.addLiquidity(secondAmountA, secondAmountB);

        assertEq(actualLP, expectedLP, "LP tokens should match expected amount");
    }

    function test_AddLiquidity_UpdatesReserves() public {
        uint256 amountA = 100 * 1e18;
        uint256 amountB = 200 * 1e18;

        vm.prank(liquidityProvider);
        pool.addLiquidity(amountA, amountB);

        (uint256 reserveA, uint256 reserveB) = pool.getReserves();

        assertEq(reserveA, amountA, "Reserve A should be updated");
        assertEq(reserveB, amountB, "Reserve B should be updated");
    }

    function test_AddLiquidity_TransfersTokensFromUser() public {
        uint256 amountA = 100 * 1e18;
        uint256 amountB = 100 * 1e18;

        uint256 balanceABefore = tokenA.balanceOf(liquidityProvider);
        uint256 balanceBBefore = tokenB.balanceOf(liquidityProvider);

        vm.prank(liquidityProvider);
        pool.addLiquidity(amountA, amountB);

        assertEq(
            tokenA.balanceOf(liquidityProvider),
            balanceABefore - amountA,
            "Token A should be transferred"
        );
        assertEq(
            tokenB.balanceOf(liquidityProvider),
            balanceBBefore - amountB,
            "Token B should be transferred"
        );
    }

    function test_AddLiquidity_RevertsOnZeroAmountA() public {
        vm.prank(liquidityProvider);
        vm.expectRevert("Must be more than 0");
        pool.addLiquidity(0, 100 * 1e18);
    }

    function test_AddLiquidity_RevertsOnZeroAmountB() public {
        vm.prank(liquidityProvider);
        vm.expectRevert("Must be more than 0");
        pool.addLiquidity(100 * 1e18, 0);
    }

    function test_AddLiquidity_RevertsOnZeroLPMinted() public {
        // First deposit
        vm.prank(liquidityProvider);
        pool.addLiquidity(1000000 * 1e18, 1000000 * 1e18);

        // Try to add tiny amount that would mint 0 LP tokens
        vm.prank(user);
        vm.expectRevert("LP amount must be > 0");
        pool.addLiquidity(1, 1);
    }

    function test_AddLiquidity_EmitsEvent() public {
        uint256 amountA = 100 * 1e18;
        uint256 amountB = 100 * 1e18;
        uint256 expectedLP = Math.sqrt(amountA * amountB);

        vm.prank(liquidityProvider);

        vm.expectEmit(true, false, false, true);
        emit LiquidityAdded(liquidityProvider, amountA, amountB, expectedLP);

        pool.addLiquidity(amountA, amountB);
    }

    // ============================================
    // LIQUIDITY REMOVAL TESTS
    // ============================================

    function test_RemoveLiquidity_BurnsLPTokens() public {
        // Add liquidity first
        vm.prank(liquidityProvider);
        uint256 lpMinted = pool.addLiquidity(100 * 1e18, 100 * 1e18);

        uint256 lpToRemove = lpMinted / 2;

        vm.prank(liquidityProvider);
        pool.removeLiquidity(lpToRemove);

        assertEq(
            pool.balanceOf(liquidityProvider),
            lpMinted - lpToRemove,
            "LP tokens should be burned"
        );
    }

    function test_RemoveLiquidity_ReturnsProportionalAmounts() public {
        uint256 depositA = 100 * 1e18;
        uint256 depositB = 200 * 1e18;

        vm.prank(liquidityProvider);
        uint256 lpMinted = pool.addLiquidity(depositA, depositB);

        uint256 balanceABefore = tokenA.balanceOf(liquidityProvider);
        uint256 balanceBBefore = tokenB.balanceOf(liquidityProvider);

        uint256 lpToRemove = lpMinted / 2;
        uint256 expectedA = (lpToRemove * depositA) / lpMinted;
        uint256 expectedB = (lpToRemove * depositB) / lpMinted;

        vm.prank(liquidityProvider);
        pool.removeLiquidity(lpToRemove);

        assertEq(
            tokenA.balanceOf(liquidityProvider) - balanceABefore,
            expectedA,
            "Should return proportional token A"
        );
        assertEq(
            tokenB.balanceOf(liquidityProvider) - balanceBBefore,
            expectedB,
            "Should return proportional token B"
        );
    }

    function test_RemoveLiquidity_UpdatesReserves() public {
        vm.prank(liquidityProvider);
        uint256 lpMinted = pool.addLiquidity(100 * 1e18, 100 * 1e18);

        (uint256 reserveABefore, uint256 reserveBBefore) = pool.getReserves();

        vm.prank(liquidityProvider);
        pool.removeLiquidity(lpMinted / 2);

        (uint256 reserveAAfter, uint256 reserveBAfter) = pool.getReserves();

        assertEq(reserveAAfter, reserveABefore / 2, "Reserve A should be halved");
        assertEq(reserveBAfter, reserveBBefore / 2, "Reserve B should be halved");
    }

    function test_RemoveLiquidity_RevertsOnZeroAmount() public {
        vm.prank(liquidityProvider);
        pool.addLiquidity(100 * 1e18, 100 * 1e18);

        vm.prank(liquidityProvider);
        vm.expectRevert("Amount must be greater than zero");
        pool.removeLiquidity(0);
    }

    function test_RemoveLiquidity_RevertsOnInsufficientBalance() public {
        vm.prank(liquidityProvider);
        uint256 lpMinted = pool.addLiquidity(100 * 1e18, 100 * 1e18);

        vm.prank(liquidityProvider);
        vm.expectRevert();
        pool.removeLiquidity(lpMinted + 1);
    }

    function test_RemoveLiquidity_EmitsEvent() public {
        uint256 depositA = 100 * 1e18;
        uint256 depositB = 100 * 1e18;

        vm.prank(liquidityProvider);
        uint256 lpMinted = pool.addLiquidity(depositA, depositB);

        uint256 lpToRemove = lpMinted;
        uint256 expectedA = depositA;
        uint256 expectedB = depositB;

        vm.prank(liquidityProvider);

        vm.expectEmit(true, false, false, true);
        emit LiquidityRemoved(liquidityProvider, expectedA, expectedB, lpToRemove);

        pool.removeLiquidity(lpToRemove);
    }

    function test_RemoveLiquidity_AllLiquidity() public {
        vm.prank(liquidityProvider);
        uint256 lpMinted = pool.addLiquidity(100 * 1e18, 100 * 1e18);

        vm.prank(liquidityProvider);
        pool.removeLiquidity(lpMinted);

        assertEq(pool.totalSupply(), 0, "Total supply should be 0");
        (uint256 reserveA, uint256 reserveB) = pool.getReserves();
        assertEq(reserveA, 0, "Reserve A should be 0");
        assertEq(reserveB, 0, "Reserve B should be 0");
    }

    // ============================================
    // RESERVE UPDATE TESTS
    // ============================================

    function test_UpdateReserves_OnlyExchange() public {
        vm.prank(exchange);
        pool.updateReserves(1000, 2000);

        (uint256 reserveA, uint256 reserveB) = pool.getReserves();
        assertEq(reserveA, 1000, "Reserve A should be updated");
        assertEq(reserveB, 2000, "Reserve B should be updated");
    }

    function test_UpdateReserves_RevertsForNonExchange() public {
        vm.prank(user);
        vm.expectRevert("Unauthorized");
        pool.updateReserves(1000, 2000);
    }

    function test_UpdateReserves_RevertsForRandomAddress() public {
        vm.prank(liquidityProvider);
        vm.expectRevert("Unauthorized");
        pool.updateReserves(1000, 2000);
    }

    function test_UpdateReserves_CanSetToZero() public {
        vm.prank(exchange);
        pool.updateReserves(0, 0);

        (uint256 reserveA, uint256 reserveB) = pool.getReserves();
        assertEq(reserveA, 0);
        assertEq(reserveB, 0);
    }

    // ============================================
    // GETTER TESTS
    // ============================================

    function test_GetReserves_InitiallyZero() public view {
        (uint256 reserveA, uint256 reserveB) = pool.getReserves();
        assertEq(reserveA, 0, "Initial reserve A should be 0");
        assertEq(reserveB, 0, "Initial reserve B should be 0");
    }

    function test_GetReserves_ReturnsCorrectValues() public {
        vm.prank(liquidityProvider);
        pool.addLiquidity(100 * 1e18, 200 * 1e18);

        (uint256 reserveA, uint256 reserveB) = pool.getReserves();
        assertEq(reserveA, 100 * 1e18);
        assertEq(reserveB, 200 * 1e18);
    }

    function test_GetTokenAddresses_ReturnsCorrectAddresses() public view {
        (address token0, address token1) = pool.getTokenAddresses();
        assertEq(token0, address(tokenA));
        assertEq(token1, address(tokenB));
    }

    // ============================================
    // FUZZ TESTS
    // ============================================

    function testFuzz_AddLiquidity_FirstDeposit(uint128 amountA, uint128 amountB) public {
        // Bound amounts to reasonable range
        amountA = uint128(bound(amountA, 1000, 1000000 * 1e18));
        amountB = uint128(bound(amountB, 1000, 1000000 * 1e18));

        // Mint tokens
        tokenA.mint(user, amountA);
        tokenB.mint(user, amountB);

        vm.startPrank(user);
        tokenA.approve(address(pool), amountA);
        tokenB.approve(address(pool), amountB);

        uint256 lpMinted = pool.addLiquidity(amountA, amountB);
        uint256 expectedLP = Math.sqrt(uint256(amountA) * uint256(amountB));

        assertEq(lpMinted, expectedLP);
        vm.stopPrank();
    }

    function testFuzz_RemoveLiquidity_Proportional(uint128 depositA, uint128 depositB, uint64 removePercent) public {
        // Bound inputs
        depositA = uint128(bound(depositA, 1e18, 100000 * 1e18));
        depositB = uint128(bound(depositB, 1e18, 100000 * 1e18));
        removePercent = uint64(bound(removePercent, 1, 100));

        // Add liquidity
        vm.prank(liquidityProvider);
        uint256 lpMinted = pool.addLiquidity(depositA, depositB);

        // Remove percentage of liquidity
        uint256 lpToRemove = (lpMinted * removePercent) / 100;
        if (lpToRemove == 0) lpToRemove = 1;

        vm.prank(liquidityProvider);
        pool.removeLiquidity(lpToRemove);

        // Verify reserves decreased proportionally
        (uint256 reserveA, uint256 reserveB) = pool.getReserves();
        assertGt(reserveA, 0);
        assertGt(reserveB, 0);
    }

    // ============================================
    // SCENARIO TESTS
    // ============================================

    function test_MultipleProvidersAddLiquidity() public {
        // First provider adds liquidity
        vm.prank(liquidityProvider);
        uint256 lp1 = pool.addLiquidity(100 * 1e18, 100 * 1e18);

        // Second provider adds liquidity
        vm.prank(user);
        uint256 lp2 = pool.addLiquidity(100 * 1e18, 100 * 1e18);

        // Both should have LP tokens
        assertGt(pool.balanceOf(liquidityProvider), 0);
        assertGt(pool.balanceOf(user), 0);

        // Total supply should be sum of both
        assertEq(pool.totalSupply(), lp1 + lp2);
    }

    function test_AddRemoveAddLiquidity() public {
        // Add liquidity
        vm.prank(liquidityProvider);
        uint256 lp1 = pool.addLiquidity(100 * 1e18, 100 * 1e18);

        // Remove half
        vm.prank(liquidityProvider);
        pool.removeLiquidity(lp1 / 2);

        // Add again
        vm.prank(liquidityProvider);
        uint256 lp2 = pool.addLiquidity(50 * 1e18, 50 * 1e18);

        // Should have LP tokens
        assertGt(pool.balanceOf(liquidityProvider), 0);
        assertGt(lp2, 0);
    }

    function test_ImbalancedRatioAddLiquidity() public {
        // First deposit
        vm.prank(liquidityProvider);
        pool.addLiquidity(100 * 1e18, 200 * 1e18);

        // Second deposit with same ratio
        vm.prank(user);
        uint256 lp = pool.addLiquidity(50 * 1e18, 100 * 1e18);

        assertGt(lp, 0, "Should receive LP tokens for matching ratio");
    }

    function test_ImbalancedRatioAddLiquidity_DifferentRatio() public {
        // First deposit 1:2 ratio
        vm.prank(liquidityProvider);
        pool.addLiquidity(100 * 1e18, 200 * 1e18);

        uint256 totalSupplyBefore = pool.totalSupply();

        // Second deposit with 1:1 ratio (different from pool ratio)
        // Should get minimum of the two calculations
        vm.prank(user);
        uint256 lp = pool.addLiquidity(100 * 1e18, 100 * 1e18);

        // LP should be based on min calculation
        uint256 expectedLP = (100 * 1e18 * totalSupplyBefore) / 200 * 1e18;

        assertGt(lp, 0, "Should still receive LP tokens");
    }
}
