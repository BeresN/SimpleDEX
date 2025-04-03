// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20; // Use a version compatible with your Pair contract and forge-std

import "forge-std/Test.sol";
import "../src/Pair.sol"; // Adjust path if your contract is elsewhere
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Keep interface for type casting

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
        // Note: Approval needed based on how swap *should* work, may not be needed for current flawed swap
        tokenA.approve(address(pair), type(uint256).max);
        tokenB.approve(address(pair), type(uint256).max);
        vm.stopPrank();
    }

    // --- Test Deployment ---
    function testDeployment() public {
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
    function testAddInitialLiquidity() public {
        // Calculate expected LP tokens (approximate for sqrt)
        // Use fixed point math lib for precision if needed, or pre-calculate
        // uint256 expectedLp = FixedPointMathLib.sqrt(uint256(AMOUNT_A_100) * uint256(AMOUNT_B_100));
        uint256 expectedLp = 100 ether; // sqrt(100e18 * 100e18) = 100e18

        vm.startPrank(liquidityProvider);
        vm.expectEmit(true, true, true, true);
        emit Pair.liquidityAdded(
            liquidityProvider,
            AMOUNT_A_100,
            AMOUNT_B_100,
            expectedLp
        );
        uint256 actualLp = pair.addLiquidity(AMOUNT_A_100, AMOUNT_B_100);
        vm.stopPrank();

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
    }

    function testAddMoreLiquidity() public {
        // Initial liquidity
        vm.prank(liquidityProvider);
        pair.addLiquidity(AMOUNT_A_100, AMOUNT_B_100);
        uint256 initialLpSupply = pair.totalSupply();
        (uint128 initialReserveA, uint128 initialReserveB) = pair.getReserves();
        uint256 initialProviderLp = pair.balanceOf(liquidityProvider);

        // Calculate expected LP for second deposit (B is limiting factor)
        uint256 expectedMoreLp = (uint256(AMOUNT_B_25) * initialLpSupply) /
            initialReserveB;

        vm.startPrank(liquidityProvider);
        vm.expectEmit(true, true, true, true);
        emit Pair.liquidityAdded(
            liquidityProvider,
            AMOUNT_A_50,
            AMOUNT_B_25,
            expectedMoreLp
        );
        uint256 actualMoreLp = pair.addLiquidity(AMOUNT_A_50, AMOUNT_B_25);
        vm.stopPrank();

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

    function testFailAddLiquidityZeroAmount() public {
        vm.startPrank(liquidityProvider);
        vm.expectRevert("Must be more than 0");
        pair.addLiquidity(0, AMOUNT_B_100);
        vm.expectRevert("Must be more than 0");
        pair.addLiquidity(AMOUNT_A_100, 0);
        vm.stopPrank();
    }

    function testFailAddLiquidityInsufficientAllowance() public {
        // Revoke allowance
        vm.startPrank(liquidityProvider);
        tokenA.approve(address(pair), 0);
        vm.expectRevert(); // Expect generic ERC20 revert "transfer amount exceeds allowance"
        pair.addLiquidity(AMOUNT_A_100, AMOUNT_B_100);
        vm.stopPrank();
    }

    function testFailAddLiquidityInsufficientBalance() public {
        uint128 excessiveAmount = uint128(INITIAL_SUPPLY + 1);
        vm.startPrank(liquidityProvider);
        vm.expectRevert(); // Expect generic ERC20 revert "transfer amount exceeds balance"
        pair.addLiquidity(excessiveAmount, AMOUNT_B_100);
        vm.stopPrank();
    }

    // --- Test removeLiquidity ---
    function testRemoveLiquidity() public {
        // Add initial liquidity
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

        uint256 lpToRemove = lpBalance / 2; // Remove half

        // Calculate expected return amounts
        uint256 expectedAmountA = (lpToRemove * initialReserveA) /
            lpTotalSupply;
        uint256 expectedAmountB = (lpToRemove * initialReserveB) /
            lpTotalSupply;

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

        // Check LP token balances
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

        // Check reserves
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

        // Check token balances (Pair)
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

        // Check token balances (Provider)
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

    function testFailRemoveLiquidityZeroAmount() public {
        vm.startPrank(liquidityProvider);
        vm.expectRevert("require(lpTokensAmount > 0)");
        pair.removeLiquidity(0);
        vm.stopPrank();
    }

    function testFailRemoveLiquidityInsufficientLp() public {
        // Add initial liquidity
        vm.prank(liquidityProvider);
        pair.addLiquidity(AMOUNT_A_100, AMOUNT_B_100);
        uint256 lpBalance = pair.balanceOf(liquidityProvider);

        vm.startPrank(liquidityProvider);
        vm.expectRevert(); // ERC20: burn amount exceeds balance
        pair.removeLiquidity(lpBalance + 1);
        vm.stopPrank();
    }

    // --- Test swap ---
    // IMPORTANT NOTE: Testing the swap function *as written* in the contract,
    // including its non-standard logic and flaws.
    function testSwapAForB_FlawedLogic() public {
        uint128 initialAmountA = 1000 ether;
        uint128 initialAmountB = 1000 ether;
        uint128 swapAmountA = 10 ether;

        // Add initial liquidity
        vm.prank(liquidityProvider);
        pair.addLiquidity(initialAmountA, initialAmountB);

        (uint128 initialReserveA, uint128 initialReserveB) = pair.getReserves();
        uint256 swapperInitialBBalance = tokenB.balanceOf(swapper);
        uint256 pairInitialBBalance = tokenB.balanceOf(address(pair));
        uint256 pairInitialABalance = tokenA.balanceOf(address(pair));

        // Calculate expected output using the contract's fee function (1% fee)
        uint256 expectedOutputB = pair.IncludeSwapFee(
            swapAmountA,
            initialReserveA,
            initialReserveB
        );

        // Simulate swap call from swapper
        vm.startPrank(swapper);
        vm.expectEmit(true, true, true, true);
        emit Pair.Swap(swapper, swapAmountA, 0, expectedOutputB, swapper);
        uint256 actualOutputB = pair.swap(swapAmountA, 0, swapper);
        vm.stopPrank();

        assertEq(actualOutputB, expectedOutputB, "Swap output B mismatch");

        // Check reserves update (based on flawed logic in contract)
        (uint128 finalReserveA, uint128 finalReserveB) = pair.getReserves();
        assertEq(
            finalReserveA,
            initialReserveA - swapAmountA,
            "Final Reserve A (Flawed Swap)"
        );
        // Flawed logic: should be initialReserveB - expectedOutputB, but contract adds input A
        assertEq(
            finalReserveB,
            initialReserveB + swapAmountA,
            "Final Reserve B (Flawed Swap)"
        );

        // Check swapper balance (received token B)
        assertEq(
            tokenB.balanceOf(swapper),
            swapperInitialBBalance + expectedOutputB,
            "Swapper final B balance"
        );

        // Check pair balance (sent token B, token A balance didn't change)
        assertEq(
            tokenB.balanceOf(address(pair)),
            pairInitialBBalance - expectedOutputB,
            "Pair final B balance"
        );
        assertEq(
            tokenA.balanceOf(address(pair)),
            pairInitialABalance,
            "Pair final A balance (should be unchanged)"
        );
    }

    // Add similar test function testSwapBForA_FlawedLogic()

    function testFailSwapZeroAmount() public {
        vm.startPrank(swapper);
        vm.expectRevert("require(amountA > 0 || amountB > 0)");
        pair.swap(0, 0, swapper);
        vm.stopPrank();
    }

    function testFailSwapInsufficientLiquidity() public {
        // Add initial liquidity
        vm.prank(liquidityProvider);
        pair.addLiquidity(AMOUNT_A_100, AMOUNT_B_100);
        (uint128 reserveA, ) = pair.getReserves();

        vm.startPrank(swapper);
        // Try swapping exactly the reserve amount or more
        vm.expectRevert("require(amountA < reserveA || amountB < reserveB)");
        pair.swap(reserveA, 0, swapper); // Swap exactly reserveA
        vm.expectRevert("require(amountA < reserveA || amountB < reserveB)");
        pair.swap(reserveA + 1, 0, swapper); // Swap more than reserveA
        vm.stopPrank();
        // Add test for reserveB as well
    }

    function testFailSwapToZeroAddress() public {
        vm.startPrank(liquidityProvider);
        pair.addLiquidity(AMOUNT_A_100, AMOUNT_B_100); // Need liquidity
        vm.startPrank(swapper);
        vm.expectRevert("require(receiver != address(0))");
        pair.swap(1 ether, 0, address(0));
        vm.stopPrank();
    }

    function testIncludeSwapFeeRevertZeroReserve() public {
        vm.expectRevert("Reserves must be greater than 0");
        pair.IncludeSwapFee(1 ether, 0, 100 ether);
        vm.expectRevert("Reserves must be greater than 0");
        pair.IncludeSwapFee(1 ether, 100 ether, 0);
    }
}
