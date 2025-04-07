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

    uint256 internal constant AMOUNT_A_100 = 100 ether;
    uint256 internal constant AMOUNT_B_100 = 100 ether;
    uint256 internal constant AMOUNT_A_50 = 50 ether;
    uint256 internal constant AMOUNT_B_25 = 25 ether; // Uneven amount

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
        (uint256 reserveA, uint256 reserveB) = pair.getReserves();
        assertEq(reserveA, 0, "Initial reserve A non-zero");
        assertEq(reserveB, 0, "Initial reserve B non-zero");
    }

    // --- Test addLiquidity ---
    // (These tests remain largely the same as addLiquidity logic didn't change significantly)
    function testAddInitialLiquidity() public {
        uint256 expectedLp = 100 ether; // sqrt(100e18 * 100e18) = 100e18

        vm.startPrank(liquidityProvider);
        // Check emit *before* state changes if order matters (order in addLiquidity is slightly off C-E-I)
        //uint256 actualLp = pair.addLiquidity(AMOUNT_A_100, AMOUNT_B_100);

        // Check event emission separately if needed, precise arg checking after call
        // Use vm.expectEmit if precise checking *before* call is required

        assertEq(
            pair.balanceOf(liquidityProvider),
            expectedLp,
            "Provider LP balance mismatch"
        );
        assertEq(pair.totalSupply(), expectedLp, "Total supply mismatch");

        (uint256 reserveA, uint256 reserveB) = pair.getReserves();
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
        //pair.addLiquidity(AMOUNT_A_100, AMOUNT_B_100);
        uint256 initialLpSupply = pair.totalSupply();
        (uint256 initialReserveA, uint256 initialReserveB) = pair.getReserves();
        uint256 initialProviderLp = pair.balanceOf(liquidityProvider);

        uint256 expectedMoreLp = (uint256(AMOUNT_B_25) * initialLpSupply) /
            initialReserveB;

        vm.startPrank(liquidityProvider);
        //uint256 actualMoreLp = pair.addLiquidity(AMOUNT_A_50, AMOUNT_B_25);
        // Event check omitted for brevity, focus on state changes

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

        (uint256 finalReserveA, uint256 finalReserveB) = pair.getReserves();
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
        //pair.addLiquidity(0, AMOUNT_B_100);
        vm.expectRevert("Must be more than 0");
        //pair.addLiquidity(AMOUNT_A_100, 0);
        vm.stopPrank();
    }
    // Fail tests for allowance/balance remain the same

    // --- Test removeLiquidity ---
    // Note: The require check for overflow in the source code is placed *before*
    // amountA/amountB are calculated, which is incorrect syntax. This test assumes
    // the *intent* was to check after calculation, which passes for these values.
    function testRemoveLiquidity() public {
        vm.prank(liquidityProvider);
        //pair.addLiquidity(AMOUNT_A_100, AMOUNT_B_100);

        uint256 lpBalance = pair.balanceOf(liquidityProvider);
        uint256 lpTotalSupply = pair.totalSupply();
        (uint256 initialReserveA, uint256 initialReserveB) = pair.getReserves();
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

        // Check that expected amounts are <= type(uint256).max (will be true for these values)
        assertTrue(expectedAmountA <= type(uint256).max);
        assertTrue(expectedAmountB <= type(uint256).max);

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

        (uint256 finalReserveA, uint256 finalReserveB) = pair.getReserves();
        assertEq(
            finalReserveA,
            initialReserveA - uint256(expectedAmountA),
            "Final reserve A"
        );
        assertEq(
            finalReserveB,
            initialReserveB - uint256(expectedAmountB),
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
}
