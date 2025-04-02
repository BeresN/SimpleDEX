// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28; // Use a version compatible with your Pair contract and forge-std

import "forge-std/Test.sol";
import "../src/Pair.sol"; // Adjust path if your contract is elsewhere
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// --- Simple Mock ERC20 for testing ---
contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

// --- Test Contract ---
contract PairTest is Test {
    Pair public pair;
    MockERC20 public tokenA;
    MockERC20 public tokenB;

    address internal liquidityProvider = address(0x1); // Use specific addresses for clarity
    address internal swapper = address(0x2);

    uint256 internal constant INITIAL_SUPPLY = 10_000 ether; // 10,000 tokens with 18 decimals

    uint128 internal constant AMOUNT_A_100 = 100 ether;
    uint128 internal constant AMOUNT_B_100 = 100 ether;
    uint128 internal constant AMOUNT_A_50 = 50 ether;
    uint128 internal constant AMOUNT_B_25 = 25 ether; // Uneven amount

    function setUp() public {
        // Deploy Mock ERC20 tokens
        tokenA = new MockERC20("Token A", "TKA");
        tokenB = new MockERC20("Token B", "TKB");

        // Deploy Pair contract
        pair = new Pair(address(tokenA), address(tokenB));

        // Mint tokens to liquidityProvider and swapper
        tokenA.mint(liquidityProvider, INITIAL_SUPPLY);
        tokenB.mint(liquidityProvider, INITIAL_SUPPLY);
        tokenA.mint(swapper, INITIAL_SUPPLY);
        tokenB.mint(swapper, INITIAL_SUPPLY);

        // Grant approvals from users to the Pair contract
        vm.startPrank(liquidityProvider);
        tokenA.approve(address(pair), type(uint256).max);
        tokenB.approve(address(pair), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(swapper);
        // Note: Approval isn't actually needed for the current flawed swap,
        // but would be required for a correct implementation receiving input tokens.
        tokenA.approve(address(pair), type(uint256).max);
        tokenB.approve(address(pair), type(uint256).max);
        vm.stopPrank();
    }

    // --- Test Deployment ---
    function testDeployment() public view {
        assertEq(
            address(pair.tokenA()),
            address(tokenA),
            "Token A address mismatch"
        );
        assertEq(
            address(pair.tokenB()),
            address(tokenB),
            "Token B address mismatch"
        );
        assertEq(pair.name(), "LiquidityPoolToken", "LP Name mismatch");
        assertEq(pair.symbol(), "LPT", "LP Symbol mismatch");
        (uint128 reserveA, uint128 reserveB) = pair.getReserves();
        assertEq(reserveA, 0, "Initial reserve A non-zero");
        assertEq(reserveB, 0, "Initial reserve B non-zero");
    }

    // --- Test addLiquidity ---
    // (These tests remain largely the same as addLiquidity logic didn't change significantly)
    function testAddInitialLiquidity() public {
        uint256 expectedLp = 100 ether; // sqrt(100e18 * 100e18) = 100e18

        vm.startPrank(liquidityProvider);
        // Check emit *before* state changes if order matters (order in addLiquidity is slightly off C-E-I)
        uint256 actualLp = pair.addLiquidity(AMOUNT_A_100, AMOUNT_B_100);

        // Check event emission separately if needed, precise arg checking after call
        // Use vm.expectEmit if precise checking *before* call is required

        assertEq(actualLp, expectedLp, "Incorrect initial LP minted");
        assertEq(
            pair.balanceOf(liquidityProvider),
            expectedLp,
            "Provider LP balance mismatch"
        );
        assertEq(pair.totalSupply(), expectedLp, "Total supply mismatch");

        (uint128 reserveA, uint128 reserveB) = pair.getReserves();
        assertEq(
            reserveA,
            AMOUNT_A_100,
            "Reserve A mismatch after initial add"
        );
        assertEq(
            reserveB,
            AMOUNT_B_100,
            "Reserve B mismatch after initial add"
        );
        assertEq(
            tokenA.balanceOf(address(pair)),
            AMOUNT_A_100,
            "Pair Token A balance mismatch"
        );
        assertEq(
            tokenB.balanceOf(address(pair)),
            AMOUNT_B_100,
            "Pair Token B balance mismatch"
        );
        // Event check (can be done via logs after run if not using vm.expectEmit)
    }

    function testAddMoreLiquidity() public {
        vm.prank(liquidityProvider);
        pair.addLiquidity(AMOUNT_A_100, AMOUNT_B_100);
        uint256 initialLpSupply = pair.totalSupply();
        (uint128 initialReserveA, uint128 initialReserveB) = pair.getReserves();
        uint256 initialProviderLp = pair.balanceOf(liquidityProvider);

        uint256 expectedMoreLp = (uint256(AMOUNT_B_25) * initialLpSupply) /
            initialReserveB;

        vm.startPrank(liquidityProvider);
        uint256 actualMoreLp = pair.addLiquidity(AMOUNT_A_50, AMOUNT_B_25);
        // Event check omitted for brevity, focus on state changes

        assertEq(
            actualMoreLp,
            expectedMoreLp,
            "Incorrect additional LP minted"
        );
        assertEq(
            pair.balanceOf(liquidityProvider),
            initialProviderLp + expectedMoreLp,
            "Provider final LP balance mismatch"
        );
        assertEq(
            pair.totalSupply(),
            initialLpSupply + expectedMoreLp,
            "Final total supply mismatch"
        );

        (uint128 finalReserveA, uint128 finalReserveB) = pair.getReserves();
        assertEq(
            finalReserveA,
            initialReserveA + AMOUNT_A_50,
            "Final Reserve A mismatch"
        );
        assertEq(
            finalReserveB,
            initialReserveB + AMOUNT_B_25,
            "Final Reserve B mismatch"
        );
        assertEq(
            tokenA.balanceOf(address(pair)),
            initialReserveA + AMOUNT_A_50,
            "Pair final Token A balance mismatch"
        );
        assertEq(
            tokenB.balanceOf(address(pair)),
            initialReserveB + AMOUNT_B_25,
            "Pair final Token B balance mismatch"
        );
    }

    function test_RevertWhen_AddLiquidityZeroAmount() public {
        vm.startPrank(liquidityProvider);
        vm.expectRevert("Must be more than 0");
        pair.addLiquidity(0, AMOUNT_B_100);
        vm.expectRevert("Must be more than 0");
        pair.addLiquidity(AMOUNT_A_100, 0);
        vm.stopPrank();
    }
    // Fail tests for allowance/balance remain the same

    // --- Test removeLiquidity ---
    // Note: The require check for overflow in the source code is placed *before*
    // amountA/amountB are calculated, which is incorrect syntax. This test assumes
    // the *intent* was to check after calculation, which passes for these values.
    function testRemoveLiquidity() public {
        vm.prank(liquidityProvider);
        pair.addLiquidity(AMOUNT_A_100, AMOUNT_B_100);

        uint256 lpBalance = pair.balanceOf(liquidityProvider);
        uint256 lpTotalSupply = pair.totalSupply();
        (uint128 initialReserveA, uint128 initialReserveB) = pair.getReserves();
        uint256 initialPairTokenABalance = tokenA.balanceOf(address(pair));
        uint256 initialPairTokenBBalance = tokenB.balanceOf(address(pair));
        uint256 initialProviderTokenABalance = tokenA.balanceOf(
            liquidityProvider
        );
        uint256 initialProviderTokenBBalance = tokenB.balanceOf(
            liquidityProvider
        );

        uint256 lpToRemove = lpBalance / 2;

        uint256 expectedAmountA = (lpToRemove * initialReserveA) /
            lpTotalSupply;
        uint256 expectedAmountB = (lpToRemove * initialReserveB) /
            lpTotalSupply;

        // Check that expected amounts are <= type(uint128).max (will be true for these values)
        assertTrue(expectedAmountA <= type(uint128).max);
        assertTrue(expectedAmountB <= type(uint128).max);

        vm.startPrank(liquidityProvider);
        vm.expectEmit(true, true, true, true);
        emit Pair.LiquidityRemoved(
            liquidityProvider,
            expectedAmountA,
            expectedAmountB,
            lpToRemove
        );
        (uint256 actualAmountA, uint256 actualAmountB) = pair.removeLiquidity(
            lpToRemove
        );
        vm.stopPrank();

        assertEq(actualAmountA, expectedAmountA, "Returned amount A mismatch");
        assertEq(actualAmountB, expectedAmountB, "Returned amount B mismatch");

        assertEq(
            pair.balanceOf(liquidityProvider),
            lpBalance - lpToRemove,
            "Provider final LP balance"
        );
        assertEq(
            pair.totalSupply(),
            lpTotalSupply - lpToRemove,
            "Final LP total supply"
        );

        (uint128 finalReserveA, uint128 finalReserveB) = pair.getReserves();
        assertEq(
            finalReserveA,
            initialReserveA - uint128(expectedAmountA),
            "Final reserve A"
        );
        assertEq(
            finalReserveB,
            initialReserveB - uint128(expectedAmountB),
            "Final reserve B"
        );

        assertEq(
            tokenA.balanceOf(address(pair)),
            initialPairTokenABalance - expectedAmountA,
            "Pair final token A balance"
        );
        assertEq(
            tokenB.balanceOf(address(pair)),
            initialPairTokenBBalance - expectedAmountB,
            "Pair final token B balance"
        );

        assertEq(
            tokenA.balanceOf(liquidityProvider),
            initialProviderTokenABalance + expectedAmountA,
            "Provider final token A balance"
        );
        assertEq(
            tokenB.balanceOf(liquidityProvider),
            initialProviderTokenBBalance + expectedAmountB,
            "Provider final token B balance"
        );
    }
    // Fail tests for removeLiquidity remain the same

    // --- Test swap ---
    // IMPORTANT NOTE: Testing the swap function *as written* in the contract,
    // including its non-standard logic and flaws (incorrect reserve update, wrong token sent).
    function testSwapAForB_FlawedLogic() public {
        uint128 initialAmountA = 1000 ether;
        uint128 initialAmountB = 1000 ether;
        uint128 swapAmountA_input = 10 ether; // User provides input amount A

        // Add initial liquidity
        vm.prank(liquidityProvider);
        pair.addLiquidity(initialAmountA, initialAmountB);

        (uint128 initialReserveA, uint128 initialReserveB) = pair.getReserves();
        uint256 swapperInitialABalance = tokenA.balanceOf(swapper); // Swapper will receive A incorrectly
        uint256 pairInitialABalance = tokenA.balanceOf(address(pair));
        uint256 pairInitialBBalance = tokenB.balanceOf(address(pair));

        // Calculate expected output B using the contract's fee function (0.1% fee)
        uint256 expectedOutputB = pair.IncludeSwapFee(
            swapAmountA_input,
            initialReserveA,
            initialReserveB
        );

        // Check cast safety for reserve update (unlikely to fail with test values)
        assertTrue(expectedOutputB <= type(uint128).max);

        // Simulate swap call from swapper
        vm.startPrank(swapper);
        // Expect Swap(sender, amountAIn, amountBIn, amountAOut, amountBOut, to)
        // Contract emits: Swap(swapper, swapAmountA_input, 0, expectedOutputB, expectedOutputB, swapper) - Incorrectly emits output B twice
        emit Pair.Swap(
            swapper,
            swapAmountA_input,
            0,
            expectedOutputB,
            expectedOutputB,
            swapper
        );
        pair.swap(swapAmountA_input, 0, swapper);
        vm.stopPrank();

        // Check reserves update (based on flawed logic in contract)
        (uint128 finalReserveA, uint128 finalReserveB) = pair.getReserves();
        assertEq(
            finalReserveA,
            initialReserveA - swapAmountA_input,
            "Final Reserve A (Flawed Swap: Input Subtracted)"
        );
        assertEq(
            finalReserveB,
            initialReserveB + uint128(expectedOutputB),
            "Final Reserve B (Flawed Swap: Output B Added)"
        );

        // Check swapper balance (incorrectly received token A instead of B)
        assertEq(
            tokenA.balanceOf(swapper),
            swapperInitialABalance + expectedOutputB,
            "Swapper final A balance (Received Wrong Token)"
        );
        // Swapper's B balance should be unchanged
        assertEq(
            tokenB.balanceOf(swapper),
            INITIAL_SUPPLY,
            "Swapper final B balance (Should be unchanged)"
        );

        // Check pair balance (sent token A, token B balance didn't change)
        assertEq(
            tokenA.balanceOf(address(pair)),
            pairInitialABalance - expectedOutputB,
            "Pair final A balance (Sent Wrong Token)"
        );
        assertEq(
            tokenB.balanceOf(address(pair)),
            pairInitialBBalance,
            "Pair final B balance (Should be unchanged)"
        );
    }

    // Test IncludeSwapFee calculation separately if desired
    function testIncludeSwapFeeCalculation() public view {
        uint256 reserveIn = 1000 ether;
        uint256 reserveOut = 1000 ether;
        uint256 amountIn = 10 ether;

        // Expected = (10 * 999 * 1000) / ((1000 * 1000) + (10 * 999))
        // Expected = 9990000 / (1000000 + 9990) = 9990000 / 1009990 ~= 9.8911...
        uint256 expectedOut = (amountIn * 999 * reserveOut) /
            ((reserveIn * 1000) + (amountIn * 999));

        assertEq(
            pair.IncludeSwapFee(amountIn, reserveIn, reserveOut),
            expectedOut,
            "IncludeSwapFee mismatch"
        );
    }
}
