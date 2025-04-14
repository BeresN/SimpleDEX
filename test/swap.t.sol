// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Pair.sol"; // Adjust path
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// --- Mock ERC20 ---
contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

// --- Test Contract ---
contract PairSwapTest is Test {
    Pair public pair;
    MockERC20 public tokenA; // Lower address in setUp
    MockERC20 public tokenB; // Higher address in setUp
    address internal tokenAddrA;
    address internal tokenAddrB;

    address internal liquidityProvider = address(0x1);
    address internal swapper = address(0x2);
    address internal otherAddress = address(0x3); // For sending output

    uint256 internal constant INITIAL_LIQUIDITY_A = 1000 ether;
    uint256 internal constant INITIAL_LIQUIDITY_B = 1000 ether;
    uint256 internal constant SWAPPER_INITIAL_BALANCE = 500 ether;

    function setUp() public {
        // Deploy tokens and determine order
        MockERC20 deployedToken1 = new MockERC20("Token A", "TKA");
        MockERC20 deployedToken2 = new MockERC20("Token B", "TKB");
        address addr1 = address(deployedToken1);
        address addr2 = address(deployedToken2);

        if (addr1 < addr2) {
            tokenA = deployedToken1;
            tokenB = deployedToken2;
            tokenAddrA = addr1;
            tokenAddrB = addr2;
        } else {
            tokenA = deployedToken2;
            tokenB = deployedToken1; // Swap instance assignment
            tokenAddrA = addr2;
            tokenAddrB = addr1; // Swap address assignment
        }

        // Deploy Pair (assuming constructor takes sorted addresses)
        pair = new Pair(tokenAddrA, tokenAddrB);

        // Mint initial balances
        tokenA.mint(liquidityProvider, INITIAL_LIQUIDITY_A);
        tokenB.mint(liquidityProvider, INITIAL_LIQUIDITY_B);
        tokenA.mint(swapper, SWAPPER_INITIAL_BALANCE);
        tokenB.mint(swapper, SWAPPER_INITIAL_BALANCE);

        // Provide initial liquidity
        vm.startPrank(liquidityProvider);
        tokenA.approve(address(pair), INITIAL_LIQUIDITY_A);
        tokenB.approve(address(pair), INITIAL_LIQUIDITY_B);
        pair.addLiquidity(
            uint128(INITIAL_LIQUIDITY_A),
            uint128(INITIAL_LIQUIDITY_B)
        );
        vm.stopPrank();
    }

    // --- Helper Function to calculate Required Input (Inverse of IncludeSwapFee) ---
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "GetAmountIn: ZERO_OUTPUT");
        require(reserveIn > 0 && reserveOut > 0, "GetAmountIn: ZERO_RESERVES");
        require(amountOut < reserveOut, "GetAmountIn: OUTPUT_EXCEEDS_RESERVE"); // Cannot take more than exists

        // Formula derived for 0.1% fee: amountIn = (amountOut * reserveIn * 1000) / ((reserveOut - amountOut) * 999) + 1
        uint256 numerator = amountOut * reserveIn * 1000;
        uint256 denominator = (reserveOut - amountOut) * 999;
        amountIn = (numerator / denominator); // Add 1 for rounding up
    }

    // --- Test swap ---

    function test_SwapAForB_HappyPath() public {
        uint128 amountBOut_desired = 10 ether; // Request 10 Token B out
        (uint256 reserveA_before, uint256 reserveB_before) = pair.getReserves();
        console.log("reserve A before: ", reserveA_before);
        console.log("reserve B before: ", reserveB_before);

        // Calculate required input A for desired output B (using 0.1% fee math)
        uint256 requiredAmountAIn = getAmountIn(
            amountBOut_desired,
            reserveA_before,
            reserveB_before
        );
        console.log("Amount of required amount a: ", requiredAmountAIn);
        assertTrue(
            requiredAmountAIn <= SWAPPER_INITIAL_BALANCE,
            "Swapper insufficient balance for test"
        );

        // 1. Swapper sends required Token A to Pair contract first
        vm.startPrank(swapper);
        tokenA.transfer(address(pair), requiredAmountAIn);
        vm.stopPrank();
        console.log("amount in pair A contract: ", requiredAmountAIn);

        // 2. Swapper calls swap requesting Token B
        uint256 swapperTokenB_before = tokenB.balanceOf(swapper);
        vm.startPrank(swapper);
        // Expect Swap(sender, amountAIn, amountBIn, amountAOut, amountBOut, to)
        emit Pair.Swap(
            swapper,
            requiredAmountAIn,
            0,
            0,
            amountBOut_desired,
            swapper
        );
        pair.swap(0, amountBOut_desired, swapper); // Request amountBOut
        vm.stopPrank();

        // --- Assertions ---
        // Swapper balances
        assertEq(
            tokenA.balanceOf(swapper),
            SWAPPER_INITIAL_BALANCE - requiredAmountAIn,
            "Swapper A balance wrong"
        );
        assertEq(
            tokenB.balanceOf(swapper),
            swapperTokenB_before + amountBOut_desired,
            "Swapper B balance wrong"
        );

        uint256 pairFinalBalanceA = tokenA.balanceOf(address(pair));
        uint256 pairFinalBalanceB = tokenB.balanceOf(address(pair));
        console.log("final A balance: ", pairFinalBalanceA);
        console.log("final B balance: ", pairFinalBalanceB);
        assertEq(
            pairFinalBalanceA,
            uint256(reserveA_before) - amountBOut_desired,
            "Pair final A balance wrong"
        );
        assertEq(
            pairFinalBalanceB,
            uint256(reserveB_before) + requiredAmountAIn,
            "Pair final B balance wrong"
        );

        (uint256 reserveA_after, uint256 reserveB_after) = pair.getReserves();
        console.log("reserve A after: ", reserveA_after);
        console.log("reserve B after: ", reserveB_after);
        assertEq(
            uint256(reserveA_after),
            pairFinalBalanceA,
            "Stored reserve A mismatch"
        );
        assertEq(
            uint256(reserveB_after),
            pairFinalBalanceB,
            "Stored reserve B mismatch"
        );
    }

    function test_SwapBForA_HappyPath() public {
        uint128 amountAOut_desired = 10 ether; // Request 10 Token A out
        (uint256 reserveA_before, uint256 reserveB_before) = pair.getReserves();
        console.log("reserve A before: ", reserveA_before);
        console.log("reserve B before: ", reserveB_before);

        // Calculate required input B for desired output A (using 0.1% fee math)
        uint256 requiredAmountBIn = getAmountIn(
            amountAOut_desired,
            reserveB_before,
            reserveA_before
        ); // Reserves reversed for formula
        assertTrue(
            requiredAmountBIn <= SWAPPER_INITIAL_BALANCE,
            "Swapper insufficient balance for test"
        );
        console.log("token b balance: ", requiredAmountBIn);
        // 1. Swapper sends required Token B to Pair contract first
        vm.startPrank(swapper);
        tokenB.transfer(address(pair), requiredAmountBIn);
        vm.stopPrank();

        // 2. Swapper calls swap requesting Token A
        uint256 swapperTokenA_before = tokenA.balanceOf(swapper);
        console.log("token a balance: ", swapperTokenA_before);
        console.log("token b balance: ", tokenB.balanceOf(swapper));

        vm.startPrank(swapper);
        // Expect Swap(sender, amountAIn, amountBIn, amountAOut, amountBOut, to)
        emit Pair.Swap(
            swapper,
            0,
            requiredAmountBIn,
            amountAOut_desired,
            0,
            swapper
        );
        pair.swap(amountAOut_desired, 0, swapper); // Request amountAOut
        vm.stopPrank();
        console.log("token a balance: ", tokenA.balanceOf(swapper));

        console.log("token b balance: ", tokenB.balanceOf(swapper));
        // --- Assertions ---
        assertEq(
            tokenB.balanceOf(swapper),
            SWAPPER_INITIAL_BALANCE - requiredAmountBIn,
            "Swapper B balance wrong"
        );
        assertEq(
            tokenA.balanceOf(swapper),
            swapperTokenA_before + amountAOut_desired,
            "Swapper A balance wrong"
        );

        uint256 pairFinalBalanceA = tokenA.balanceOf(address(pair));
        uint256 pairFinalBalanceB = tokenB.balanceOf(address(pair));
        assertEq(
            pairFinalBalanceA,
            uint256(reserveA_before) - amountAOut_desired,
            "Pair final A balance wrong"
        );
        assertEq(
            pairFinalBalanceB,
            uint256(reserveB_before) + requiredAmountBIn,
            "Pair final B balance wrong"
        );

        (uint256 reserveA_after, uint256 reserveB_after) = pair.getReserves();
        assertEq(
            uint256(reserveA_after),
            pairFinalBalanceA,
            "Stored reserve A mismatch"
        );
        assertEq(
            uint256(reserveB_after),
            pairFinalBalanceB,
            "Stored reserve B mismatch"
        );
    }

    function test_RevertWhen_SwapZeroOutput() public {
        vm.startPrank(swapper);
        vm.expectRevert("Swap: ZERO_OUTPUT_AMOUNT");
        pair.swap(0, 0, swapper);
        vm.stopPrank();
    }

    function test_RevertWhen_SwapInvalidTo() public {
        vm.startPrank(swapper);
        vm.expectRevert("Swap: INVALID_TO");
        pair.swap(0, 1 ether, address(pair));
        // Add tests for sending to token addresses if needed
        vm.stopPrank();
    }

    function test_RevertWhen_SwapNoInputSent() public {
        uint128 amountBOut_desired = 10 ether;
        // Swapper calls swap WITHOUT sending any input tokens first
        vm.startPrank(swapper);
        vm.expectRevert("Swap: INSUFFICIENT_INPUT_AMOUNT");
        pair.swap(0, amountBOut_desired, swapper);
        vm.stopPrank();
    }
}
