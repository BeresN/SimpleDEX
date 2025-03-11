// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../src/Exchange.sol";
import "../src/LiquidityPool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1_000_000 ether);
    }
}

contract ExchangeTest is Test {
    MockERC20 tokenA;
    MockERC20 tokenB;
    LiquidityPool pool;
    Exchange exchange;

    address user = address(0x123);

    function setUp() public {
        console.log("Starting setup...");

        // Deploy tokens
        tokenA = new MockERC20("TokenA", "TKA");
        tokenB = new MockERC20("TokenB", "TKB");
        console.log("Tokens deployed");

        // Deploy pool FIRST to pass valid address
        pool = new LiquidityPool(
            address(tokenA),
            address(tokenB),
            address(this) // Owner or Exchange controller
        );
        console.log("LiquidityPool deployed");

        // Now deploy exchange with a valid pool address
        exchange = new Exchange(address(pool), address(this));
        console.log("Exchange deployed");

        // Mint and transfer tokens
        tokenA.transfer(user, 500_000 ether);
        tokenB.transfer(user, 500_000 ether);
        console.log("Tokens transferred to user");

        // Approve tokens for both pool and exchange
        vm.startPrank(user);
        tokenA.approve(address(pool), type(uint256).max);
        tokenB.approve(address(pool), type(uint256).max);
        tokenA.approve(address(exchange), type(uint256).max);
        tokenB.approve(address(exchange), type(uint256).max);
        console.log("Tokens approved");

        // Add initial liquidity
        pool.addLiquidity(100_000 ether, 100_000 ether);
        console.log("Liquidity added");

        vm.stopPrank();
    }

    function testInitialSetup() public view {
        (address poolTokenA, address poolTokenB) = pool.getTokenAddresses();
        assertEq(poolTokenA, address(tokenA));
        assertEq(poolTokenB, address(tokenB));

        assertEq(exchange.tokenA(), address(tokenA));
        assertEq(exchange.tokenB(), address(tokenB));

        (uint256 reserveA, uint256 reserveB) = pool.getReserves();
        assertEq(reserveA, 100_000 ether);
        assertEq(reserveB, 100_000 ether);
    }

    function testSwapTokenAToB() public {
        vm.startPrank(user);

        uint256 amountIn = 10_000 ether;
        uint256 balanceBefore = tokenB.balanceOf(user);

        uint256 amountOut = exchange.swapTokenAToB(amountIn);

        assertGt(amountOut, 0);
        assertEq(tokenA.balanceOf(user), 490_000 ether);
        assertEq(tokenB.balanceOf(user), balanceBefore + amountOut);

        (uint256 reserveA, uint256 reserveB) = pool.getReserves();
        assertEq(reserveA, 110_000 ether);
        assertEq(reserveB, 100_000 ether - amountOut);

        vm.stopPrank();
    }

    function testSwapTokenBToA() public {
        vm.startPrank(user);

        uint256 amountIn = 10_000 ether;
        uint256 balanceBefore = tokenA.balanceOf(user);
        console.log("User TokenA Balance:", tokenA.balanceOf(user));
        uint256 amountOut = exchange.swapTokenBToA(amountIn);
        console.log(
            "Exchange TokenA Balance:",
            tokenA.balanceOf(address(exchange))
        );

        // Ensure output is greater than zero
        assertGt(amountOut, 0);

        // Check user balances after swap (with fee consideration)
        uint256 expectedTokenB = 500_000 ether - amountIn;
        assertEq(tokenB.balanceOf(user), expectedTokenB);
        assertEq(tokenA.balanceOf(user), balanceBefore + amountOut);

        // Check pool reserves
        (uint256 reserveA, uint256 reserveB) = pool.getReserves();
        console.log("Pool Reserves:", reserveA, reserveB);

        uint256 expectedReserveA = 100_000 ether - amountOut;
        uint256 expectedReserveB = 100_000 ether + (amountIn * 99) / 100;
        assertEq(reserveA, expectedReserveA);
        assertEq(reserveB, expectedReserveB);

        vm.stopPrank();
    }

    function test_RevertWhen_SwapWithInsufficientReserves() public {
        vm.startPrank(user);

        uint256 amountIn = 500_000 ether; // Exceeds reserve
        exchange.swapTokenAToB(amountIn);

        vm.stopPrank();
    }

    function testGetOutputAmountFromSwap() public view {
        uint256 inputAmount = 10_000 ether;
        uint256 outputAmount = exchange.getOutputAmountFromSwap(
            inputAmount,
            100_000 ether,
            100_000 ether
        );

        assertGt(outputAmount, 0);
    }
}
