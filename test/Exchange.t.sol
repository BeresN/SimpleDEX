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
        tokenA = new MockERC20("TokenA", "TKA");
        tokenB = new MockERC20("TokenB", "TKB");

        pool = new LiquidityPool(
            address(tokenA),
            address(tokenB),
            address(this)
        );
        exchange = new Exchange(address(pool), address(this));

        // Mint tokens to user and approve
        tokenA.transfer(user, 500_000 ether);
        tokenB.transfer(user, 500_000 ether);

        vm.startPrank(user);
        tokenA.approve(address(pool), type(uint256).max);
        tokenB.approve(address(pool), type(uint256).max);
        tokenA.approve(address(exchange), type(uint256).max);
        tokenB.approve(address(exchange), type(uint256).max);

        // Add initial liquidity
        pool.addLiquidity(100_000 ether, 100_000 ether);
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

        uint256 amountOut = exchange.swapTokenBToA(amountIn);

        assertGt(amountOut, 0);
        assertEq(tokenB.balanceOf(user), 490_000 ether);
        assertEq(tokenA.balanceOf(user), balanceBefore + amountOut);

        (uint256 reserveA, uint256 reserveB) = pool.getReserves();
        assertEq(reserveA, 100_000 ether - amountOut);
        assertEq(reserveB, 110_000 ether);

        vm.stopPrank();
    }

    function testOnlyOwnerCanTransferTokens() public {
        uint256 ownerBalanceBefore = tokenA.balanceOf(address(this));
        uint256 amount = 30 ether;
        exchange.transferTokens(address(tokenA), address(this), amount);
        assertEq(tokenA.balanceOf(address(this)), amount, "Transfer failed");
        uint256 ownerBalanceAfter = tokenA.balanceOf(address(this));
        assertEq(ownerBalanceAfter, ownerBalanceBefore + amount);

        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(user);
        exchange.transferTokens(address(tokenA), user, amount);
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
