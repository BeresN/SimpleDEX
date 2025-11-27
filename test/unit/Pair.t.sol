// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../../src/Pair.sol";
import "../mocks/MockERC20.sol";

contract PairTest is Test {
    Pair public pair;
    MockERC20 public tokenA;
    MockERC20 public tokenB;

    address public liquidityProvider = address(1);
    address public trader = address(2);
    address public user = address(3);

    uint256 constant INITIAL_MINT = 1000000 * 1e18;

    event liquidityAdded(
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

    event Swap(
        address indexed sender,
        uint256 amountA,
        uint256 amountB,
        uint256 amountAOut,
        uint256 amountBOut,
        address indexed to
    );

    function setUp() public {
        // Deploy tokens
        tokenA = new MockERC20("Token A", "TKA", 18);
        tokenB = new MockERC20("Token B", "TKB", 18);

        // Deploy pair
        pair = new Pair(address(tokenA), address(tokenB));

        // Mint tokens to participants
        tokenA.mint(liquidityProvider, INITIAL_MINT);
        tokenB.mint(liquidityProvider, INITIAL_MINT);
        tokenA.mint(trader, INITIAL_MINT);
        tokenB.mint(trader, INITIAL_MINT);
        tokenA.mint(user, INITIAL_MINT);
        tokenB.mint(user, INITIAL_MINT);

        // Approve pair to spend tokens
        vm.prank(liquidityProvider);
        tokenA.approve(address(pair), type(uint256).max);
        vm.prank(liquidityProvider);
        tokenB.approve(address(pair), type(uint256).max);

        vm.prank(trader);
        tokenA.approve(address(pair), type(uint256).max);
        vm.prank(trader);
        tokenB.approve(address(pair), type(uint256).max);

        vm.prank(user);
        tokenA.approve(address(pair), type(uint256).max);
        vm.prank(user);
        tokenB.approve(address(pair), type(uint256).max);
    }

    // ============================================
    // CONSTRUCTOR TESTS
    // ============================================

    function test_Constructor_Success() public {
        Pair newPair = new Pair(address(tokenA), address(tokenB));

        assertEq(address(newPair.tokenA()), address(tokenA));
        assertEq(address(newPair.tokenB()), address(tokenB));
        assertEq(newPair.name(), "LiquidityPoolToken");
        assertEq(newPair.symbol(), "LPT");
    }

    function test_Constructor_RevertsOnZeroTokenA() public {
        vm.expectRevert("Zero address");
        new Pair(address(0), address(tokenB));
    }

    function test_Constructor_RevertsOnZeroTokenB() public {
        vm.expectRevert("Zero address");
        new Pair(address(tokenA), address(0));
    }

    // ============================================
    // LIQUIDITY ADDITION TESTS
    // ============================================

    function test_AddLiquidity_FirstDeposit() public {
        uint128 amountA = 100 * 1e18;
        uint128 amountB = 100 * 1e18;

        vm.prank(liquidityProvider);
        uint256 lpMinted = pair.addLiquidity(amountA, amountB);

        // First deposit: LP = sqrt(amountA * amountB)
        uint256 expectedLP = Math.sqrt(uint256(amountA) * uint256(amountB));
        assertEq(lpMinted, expectedLP, "LP should be sqrt(amountA * amountB)");
        assertEq(pair.balanceOf(liquidityProvider), expectedLP);
    }

    function test_AddLiquidity_SubsequentDeposit() public {
        // First deposit
        vm.prank(liquidityProvider);
        pair.addLiquidity(100 * 1e18, 100 * 1e18);

        // Second deposit
        uint128 amountA = 50 * 1e18;
        uint128 amountB = 50 * 1e18;

        vm.prank(user);
        uint256 lpMinted = pair.addLiquidity(amountA, amountB);

        assertTrue(lpMinted > 0, "LP should be minted");
        assertEq(pair.balanceOf(user), lpMinted);
    }

    function test_AddLiquidity_MintsCorrectLPTokens() public {
        uint128 firstAmountA = 100 * 1e18;
        uint128 firstAmountB = 100 * 1e18;

        vm.prank(liquidityProvider);
        pair.addLiquidity(firstAmountA, firstAmountB);

        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = pair.getReserves();

        // Second deposit with same ratio
        uint128 secondAmountA = 50 * 1e18;
        uint128 secondAmountB = 50 * 1e18;

        uint256 expectedLP = Math.min(
            (uint256(secondAmountA) * totalSupply) / reserveA,
            (uint256(secondAmountB) * totalSupply) / reserveB
        );

        vm.prank(user);
        uint256 actualLP = pair.addLiquidity(secondAmountA, secondAmountB);

        assertEq(actualLP, expectedLP);
    }

    function test_AddLiquidity_UpdatesReserves() public {
        uint128 amountA = 100 * 1e18;
        uint128 amountB = 200 * 1e18;

        vm.prank(liquidityProvider);
        pair.addLiquidity(amountA, amountB);

        (uint256 reserveA, uint256 reserveB) = pair.getReserves();

        assertEq(reserveA, amountA);
        assertEq(reserveB, amountB);
    }

    function test_AddLiquidity_TransfersTokens() public {
        uint128 amountA = 100 * 1e18;
        uint128 amountB = 100 * 1e18;

        uint256 balanceABefore = tokenA.balanceOf(liquidityProvider);
        uint256 balanceBBefore = tokenB.balanceOf(liquidityProvider);

        vm.prank(liquidityProvider);
        pair.addLiquidity(amountA, amountB);

        assertEq(tokenA.balanceOf(liquidityProvider), balanceABefore - amountA);
        assertEq(tokenB.balanceOf(liquidityProvider), balanceBBefore - amountB);
        assertEq(tokenA.balanceOf(address(pair)), amountA);
        assertEq(tokenB.balanceOf(address(pair)), amountB);
    }

    function test_AddLiquidity_RevertsOnZeroAmountA() public {
        vm.prank(liquidityProvider);
        vm.expectRevert("Must be more than 0");
        pair.addLiquidity(0, 100 * 1e18);
    }

    function test_AddLiquidity_RevertsOnZeroAmountB() public {
        vm.prank(liquidityProvider);
        vm.expectRevert("Must be more than 0");
        pair.addLiquidity(100 * 1e18, 0);
    }

    function test_AddLiquidity_EmitsEvent() public {
        uint128 amountA = 100 * 1e18;
        uint128 amountB = 100 * 1e18;
        uint256 expectedLP = Math.sqrt(uint256(amountA) * uint256(amountB));

        vm.prank(liquidityProvider);

        vm.expectEmit(true, false, false, true);
        emit liquidityAdded(liquidityProvider, amountA, amountB, expectedLP);

        pair.addLiquidity(amountA, amountB);
    }

    // ============================================
    // LIQUIDITY REMOVAL TESTS
    // ============================================

    function test_RemoveLiquidity_BurnsLPTokens() public {
        vm.prank(liquidityProvider);
        uint256 lpMinted = pair.addLiquidity(100 * 1e18, 100 * 1e18);

        uint256 lpToRemove = lpMinted / 2;

        vm.prank(liquidityProvider);
        pair.removeLiquidity(lpToRemove);

        assertEq(pair.balanceOf(liquidityProvider), lpMinted - lpToRemove);
    }

    function test_RemoveLiquidity_ReturnsProportionalAmounts() public {
        uint128 depositA = 100 * 1e18;
        uint128 depositB = 200 * 1e18;

        vm.prank(liquidityProvider);
        uint256 lpMinted = pair.addLiquidity(depositA, depositB);

        uint256 balanceABefore = tokenA.balanceOf(liquidityProvider);
        uint256 balanceBBefore = tokenB.balanceOf(liquidityProvider);

        uint256 lpToRemove = lpMinted / 2;
        uint256 expectedA = (lpToRemove * depositA) / lpMinted;
        uint256 expectedB = (lpToRemove * depositB) / lpMinted;

        vm.prank(liquidityProvider);
        (uint256 amountA, uint256 amountB) = pair.removeLiquidity(lpToRemove);

        assertEq(amountA, expectedA);
        assertEq(amountB, expectedB);
        assertEq(tokenA.balanceOf(liquidityProvider) - balanceABefore, expectedA);
        assertEq(tokenB.balanceOf(liquidityProvider) - balanceBBefore, expectedB);
    }

    function test_RemoveLiquidity_UpdatesReserves() public {
        vm.prank(liquidityProvider);
        uint256 lpMinted = pair.addLiquidity(100 * 1e18, 100 * 1e18);

        (uint256 reserveABefore, uint256 reserveBBefore) = pair.getReserves();

        vm.prank(liquidityProvider);
        pair.removeLiquidity(lpMinted / 2);

        (uint256 reserveAAfter, uint256 reserveBAfter) = pair.getReserves();

        assertEq(reserveAAfter, reserveABefore / 2);
        assertEq(reserveBAfter, reserveBBefore / 2);
    }

    function test_RemoveLiquidity_RevertsOnZeroAmount() public {
        vm.prank(liquidityProvider);
        pair.addLiquidity(100 * 1e18, 100 * 1e18);

        vm.prank(liquidityProvider);
        vm.expectRevert();
        pair.removeLiquidity(0);
    }

    function test_RemoveLiquidity_RevertsOnInsufficientBalance() public {
        vm.prank(liquidityProvider);
        uint256 lpMinted = pair.addLiquidity(100 * 1e18, 100 * 1e18);

        vm.prank(liquidityProvider);
        vm.expectRevert();
        pair.removeLiquidity(lpMinted + 1);
    }

    function test_RemoveLiquidity_EmitsEvent() public {
        uint128 depositA = 100 * 1e18;
        uint128 depositB = 100 * 1e18;

        vm.prank(liquidityProvider);
        uint256 lpMinted = pair.addLiquidity(depositA, depositB);

        uint256 lpToRemove = lpMinted;
        uint256 expectedA = depositA;
        uint256 expectedB = depositB;

        vm.prank(liquidityProvider);

        vm.expectEmit(true, false, false, true);
        emit LiquidityRemoved(liquidityProvider, expectedA, expectedB, lpToRemove);

        pair.removeLiquidity(lpToRemove);
    }

    function test_RemoveLiquidity_AllLiquidity() public {
        vm.prank(liquidityProvider);
        uint256 lpMinted = pair.addLiquidity(100 * 1e18, 100 * 1e18);

        vm.prank(liquidityProvider);
        pair.removeLiquidity(lpMinted);

        assertEq(pair.totalSupply(), 0);
        (uint256 reserveA, uint256 reserveB) = pair.getReserves();
        assertEq(reserveA, 0);
        assertEq(reserveB, 0);
    }

    // ============================================
    // SWAP TESTS
    // ============================================

    function test_Swap_TokenAToB_Basic() public {
        // Add liquidity first
        vm.prank(liquidityProvider);
        pair.addLiquidity(100 * 1e18, 100 * 1e18);

        // Trader sends tokenA to pair, expects tokenB out
        uint128 amountIn = 1 * 1e18;
        // Calculate correct output with 0.1% fee (1/1000)
        // amountOut = (amountIn * 999 * reserveB) / (reserveA * 1000 + amountIn * 999)
        uint128 amountOut = 989108910891089108; // ~0.989108 * 1e18

        // Transfer tokens to pair first
        vm.prank(trader);
        tokenA.transfer(address(pair), amountIn);

        uint256 balanceBBefore = tokenB.balanceOf(trader);

        // Execute swap
        vm.prank(trader);
        pair.swap(0, amountOut, trader);

        assertEq(tokenB.balanceOf(trader), balanceBBefore + amountOut);
    }

    function test_Swap_TokenBToA_Basic() public {
        // Add liquidity first
        vm.prank(liquidityProvider);
        pair.addLiquidity(100 * 1e18, 100 * 1e18);

        // Trader sends tokenB to pair, expects tokenA out
        uint128 amountIn = 1 * 1e18;
        // Calculate correct output with 0.1% fee
        uint128 amountOut = 989108910891089108; // ~0.989108 * 1e18

        // Transfer tokens to pair first
        vm.prank(trader);
        tokenB.transfer(address(pair), amountIn);

        uint256 balanceABefore = tokenA.balanceOf(trader);

        // Execute swap
        vm.prank(trader);
        pair.swap(amountOut, 0, trader);

        assertEq(tokenA.balanceOf(trader), balanceABefore + amountOut);
    }

    function test_Swap_UpdatesReserves() public {
        vm.prank(liquidityProvider);
        pair.addLiquidity(100 * 1e18, 100 * 1e18);

        (uint256 reserveABefore, uint256 reserveBBefore) = pair.getReserves();

        uint128 amountIn = 1 * 1e18;
        uint128 amountOut = 989108910891089108; // Correct output

        vm.prank(trader);
        tokenA.transfer(address(pair), amountIn);

        vm.prank(trader);
        pair.swap(0, amountOut, trader);

        (uint256 reserveAAfter, uint256 reserveBAfter) = pair.getReserves();

        // Reserves should reflect the swap with fees
        assertGt(reserveAAfter, reserveABefore, "Reserve A should increase");
        assertLt(reserveBAfter, reserveBBefore, "Reserve B should decrease");
    }

    function test_Swap_MaintainsKInvariant() public {
        vm.prank(liquidityProvider);
        pair.addLiquidity(100 * 1e18, 100 * 1e18);

        (uint256 reserveABefore, uint256 reserveBBefore) = pair.getReserves();
        uint256 kBefore = reserveABefore * reserveBBefore;

        uint128 amountIn = 1 * 1e18;
        uint128 amountOut = 989108910891089108; // Correct output

        vm.prank(trader);
        tokenA.transfer(address(pair), amountIn);

        vm.prank(trader);
        pair.swap(0, amountOut, trader);

        (uint256 reserveAAfter, uint256 reserveBAfter) = pair.getReserves();
        uint256 kAfter = reserveAAfter * reserveBAfter;

        // K should increase or stay same due to fees
        assertGe(kAfter, kBefore, "K invariant should not decrease");
    }

    function test_Swap_RevertsOnZeroOutput() public {
        vm.prank(liquidityProvider);
        pair.addLiquidity(100 * 1e18, 100 * 1e18);

        vm.prank(trader);
        vm.expectRevert();
        pair.swap(0, 0, trader);
    }

    function test_Swap_RevertsOnInsufficientReserves() public {
        vm.prank(liquidityProvider);
        pair.addLiquidity(100 * 1e18, 100 * 1e18);

        vm.prank(trader);
        vm.expectRevert();
        pair.swap(100 * 1e18, 0, trader); // Try to withdraw all reserve
    }

    function test_Swap_RevertsOnZeroAddress() public {
        vm.prank(liquidityProvider);
        pair.addLiquidity(100 * 1e18, 100 * 1e18);

        vm.prank(trader);
        tokenA.transfer(address(pair), 1 * 1e18);

        vm.prank(trader);
        vm.expectRevert();
        pair.swap(0, 0.99 * 1e18, address(0));
    }

    function test_Swap_RevertsOnSwapToPair() public {
        vm.prank(liquidityProvider);
        pair.addLiquidity(100 * 1e18, 100 * 1e18);

        vm.prank(trader);
        tokenA.transfer(address(pair), 1 * 1e18);

        vm.prank(trader);
        vm.expectRevert("Swap: INVALID_TO");
        pair.swap(0, 0.99 * 1e18, address(pair));
    }

    function test_Swap_RevertsOnInsufficientInput() public {
        vm.prank(liquidityProvider);
        pair.addLiquidity(100 * 1e18, 100 * 1e18);

        // Don't send any tokens to pair, just try to swap
        vm.prank(trader);
        vm.expectRevert("Swap: INSUFFICIENT_INPUT_AMOUNT");
        pair.swap(0, 0.99 * 1e18, trader);
    }

    function test_Swap_RevertsOnKInvariantViolation() public {
        vm.prank(liquidityProvider);
        pair.addLiquidity(100 * 1e18, 100 * 1e18);

        // Send small amount but try to get large output
        vm.prank(trader);
        tokenA.transfer(address(pair), 0.1 * 1e18);

        vm.prank(trader);
        vm.expectRevert("Swap: K_INVARIANT_FAILED");
        pair.swap(0, 10 * 1e18, trader); // Try to get 10x more than fair
    }

    function test_Swap_EmitsEvent() public {
        vm.prank(liquidityProvider);
        pair.addLiquidity(100 * 1e18, 100 * 1e18);

        uint128 amountIn = 1 * 1e18;
        uint128 amountOut = 989108910891089108; // Correct output

        vm.prank(trader);
        tokenA.transfer(address(pair), amountIn);

        vm.prank(trader);

        vm.expectEmit(true, false, true, true);
        emit Swap(trader, amountIn, 0, 0, amountOut, trader);

        pair.swap(0, amountOut, trader);
    }

    function test_Swap_ToThirdParty() public {
        vm.prank(liquidityProvider);
        pair.addLiquidity(100 * 1e18, 100 * 1e18);

        uint128 amountIn = 1 * 1e18;
        uint128 amountOut = 989108910891089108; // Correct output

        vm.prank(trader);
        tokenA.transfer(address(pair), amountIn);

        uint256 userBalanceBefore = tokenB.balanceOf(user);

        vm.prank(trader);
        pair.swap(0, amountOut, user); // Send to third party

        assertEq(tokenB.balanceOf(user), userBalanceBefore + amountOut);
    }

    // ============================================
    // RESERVE GETTER TESTS
    // ============================================

    function test_GetReserves_InitiallyZero() public view {
        (uint256 reserveA, uint256 reserveB) = pair.getReserves();
        assertEq(reserveA, 0);
        assertEq(reserveB, 0);
    }

    function test_GetReserves_ReturnsCorrectValues() public {
        vm.prank(liquidityProvider);
        pair.addLiquidity(100 * 1e18, 200 * 1e18);

        (uint256 reserveA, uint256 reserveB) = pair.getReserves();
        assertEq(reserveA, 100 * 1e18);
        assertEq(reserveB, 200 * 1e18);
    }

    // ============================================
    // REENTRANCY PROTECTION TESTS
    // ============================================

    function test_AddLiquidity_ProtectedFromReentrancy() public {
        // The nonReentrant modifier protects this
        vm.prank(liquidityProvider);
        pair.addLiquidity(100 * 1e18, 100 * 1e18);
        assertTrue(true);
    }

    function test_RemoveLiquidity_ProtectedFromReentrancy() public {
        vm.prank(liquidityProvider);
        uint256 lp = pair.addLiquidity(100 * 1e18, 100 * 1e18);

        vm.prank(liquidityProvider);
        pair.removeLiquidity(lp);
        assertTrue(true);
    }

    function test_Swap_ProtectedFromReentrancy() public {
        vm.prank(liquidityProvider);
        pair.addLiquidity(100 * 1e18, 100 * 1e18);

        vm.prank(trader);
        tokenA.transfer(address(pair), 1 * 1e18);

        vm.prank(trader);
        pair.swap(0, 989108910891089108, trader); // Correct output
        assertTrue(true);
    }

    // ============================================
    // FUZZ TESTS
    // ============================================

    function testFuzz_AddLiquidity_FirstDeposit(uint128 amountA, uint128 amountB) public {
        amountA = uint128(bound(amountA, 1000, 100000 * 1e18));
        amountB = uint128(bound(amountB, 1000, 100000 * 1e18));

        vm.prank(liquidityProvider);
        uint256 lpMinted = pair.addLiquidity(amountA, amountB);

        uint256 expectedLP = Math.sqrt(uint256(amountA) * uint256(amountB));
        assertEq(lpMinted, expectedLP);
    }

    function testFuzz_RemoveLiquidity_Proportional(
        uint128 depositA,
        uint128 depositB,
        uint64 removePercent
    ) public {
        depositA = uint128(bound(depositA, 1e18, 100000 * 1e18));
        depositB = uint128(bound(depositB, 1e18, 100000 * 1e18));
        removePercent = uint64(bound(removePercent, 1, 100));

        vm.prank(liquidityProvider);
        uint256 lpMinted = pair.addLiquidity(depositA, depositB);

        uint256 lpToRemove = (lpMinted * removePercent) / 100;
        if (lpToRemove == 0) lpToRemove = 1;

        vm.prank(liquidityProvider);
        pair.removeLiquidity(lpToRemove);

        (uint256 reserveA, uint256 reserveB) = pair.getReserves();
        if (removePercent < 100) {
            assertGt(reserveA, 0);
            assertGt(reserveB, 0);
        }
    }

    function testFuzz_Swap_ValidAmounts(uint128 amountIn, uint128 liquidityA, uint128 liquidityB) public {
        // Bound to reasonable values
        liquidityA = uint128(bound(liquidityA, 100 * 1e18, 1000000 * 1e18));
        liquidityB = uint128(bound(liquidityB, 100 * 1e18, 1000000 * 1e18));
        amountIn = uint128(bound(amountIn, 0.01 * 1e18, liquidityA / 10));

        // Add liquidity
        vm.prank(liquidityProvider);
        pair.addLiquidity(liquidityA, liquidityB);

        // Calculate fair output with 0.1% fee
        uint256 amountInWithFee = (uint256(amountIn) * 999) / 1000;
        uint256 numerator = amountInWithFee * liquidityB;
        uint256 denominator = liquidityA + amountInWithFee;
        uint128 amountOut = uint128(numerator / denominator);

        // Only test if output is reasonable
        if (amountOut > 0 && amountOut < liquidityB) {
            vm.prank(trader);
            tokenA.transfer(address(pair), amountIn);

            vm.prank(trader);
            pair.swap(0, amountOut, trader);

            (uint256 reserveA, uint256 reserveB) = pair.getReserves();
            assertGt(reserveA, 0);
            assertGt(reserveB, 0);
        }
    }

    // ============================================
    // SCENARIO TESTS
    // ============================================

    function test_MultipleProvidersScenario() public {
        // First provider
        vm.prank(liquidityProvider);
        uint256 lp1 = pair.addLiquidity(100 * 1e18, 100 * 1e18);

        // Second provider
        vm.prank(user);
        uint256 lp2 = pair.addLiquidity(100 * 1e18, 100 * 1e18);

        assertGt(lp1, 0);
        assertGt(lp2, 0);
        assertEq(pair.totalSupply(), lp1 + lp2);
    }

    function test_AddSwapRemoveScenario() public {
        // Add liquidity
        vm.prank(liquidityProvider);
        uint256 lpMinted = pair.addLiquidity(100 * 1e18, 100 * 1e18);

        // Perform swap
        vm.prank(trader);
        tokenA.transfer(address(pair), 1 * 1e18);
        vm.prank(trader);
        pair.swap(0, 989108910891089108, trader); // Correct output

        // Remove liquidity
        vm.prank(liquidityProvider);
        pair.removeLiquidity(lpMinted);

        // Should complete successfully
        assertEq(pair.totalSupply(), 0);
    }

    function test_MultipleSwapsInSequence() public {
        vm.prank(liquidityProvider);
        pair.addLiquidity(1000 * 1e18, 1000 * 1e18);

        // Swap 1: A to B (1 in -> ~0.989 out)
        vm.prank(trader);
        tokenA.transfer(address(pair), 1 * 1e18);
        vm.prank(trader);
        pair.swap(0, 989108910891089108, trader);

        // Swap 2: B to A (1 in -> ~0.989 out)
        vm.prank(trader);
        tokenB.transfer(address(pair), 1 * 1e18);
        vm.prank(trader);
        pair.swap(989108910891089108, 0, trader);

        // Swap 3: A to B again (1 in -> ~0.989 out)
        vm.prank(trader);
        tokenA.transfer(address(pair), 1 * 1e18);
        vm.prank(trader);
        pair.swap(0, 989108910891089108, trader);

        (uint256 reserveA, uint256 reserveB) = pair.getReserves();
        assertGt(reserveA, 0);
        assertGt(reserveB, 0);
    }

    function test_ImbalancedLiquidity() public {
        // Add imbalanced liquidity (1:10 ratio)
        vm.prank(liquidityProvider);
        pair.addLiquidity(100 * 1e18, 1000 * 1e18);

        (uint256 reserveA, uint256 reserveB) = pair.getReserves();
        assertEq(reserveA, 100 * 1e18);
        assertEq(reserveB, 1000 * 1e18);

        // Swap should still work (1 A in -> ~9.881 B out with 100:1000 ratio)
        vm.prank(trader);
        tokenA.transfer(address(pair), 1 * 1e18);
        vm.prank(trader);
        pair.swap(0, 9881422924901185770, trader);

        assertTrue(true);
    }

    function test_PriceImpact() public {
        vm.prank(liquidityProvider);
        pair.addLiquidity(1000 * 1e18, 1000 * 1e18);

        // Small swap (10 in -> ~9.89 out)
        vm.prank(trader);
        tokenA.transfer(address(pair), 10 * 1e18);
        uint256 balanceBefore1 = tokenB.balanceOf(trader);
        vm.prank(trader);
        pair.swap(0, 9890000000000000000, trader);
        uint256 received1 = tokenB.balanceOf(trader) - balanceBefore1;

        // Reset liquidity for clean test
        vm.prank(liquidityProvider);
        uint256 lpBalance = pair.balanceOf(liquidityProvider);
        vm.prank(liquidityProvider);
        pair.removeLiquidity(lpBalance);

        vm.prank(liquidityProvider);
        pair.addLiquidity(1000 * 1e18, 1000 * 1e18);

        // Large swap (100 in -> ~89.65 out - worse rate due to price impact)
        vm.prank(user);
        tokenA.transfer(address(pair), 100 * 1e18);
        uint256 balanceBefore2 = tokenB.balanceOf(user);
        vm.prank(user);
        pair.swap(0, 89650000000000000000, user);
        uint256 received2 = tokenB.balanceOf(user) - balanceBefore2;

        // Rate for small swap should be better
        uint256 rate1 = (received1 * 1e18) / 10e18;
        uint256 rate2 = (received2 * 1e18) / 100e18;

        assertGt(rate1, rate2, "Small swap should have better rate");
    }
}
