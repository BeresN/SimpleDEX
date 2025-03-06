// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../src/LiquidityPool.sol";
import "../src/Exchange.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract LiquidityPoolExchangeTest is Test {
    LiquidityPool public pool;
    Exchange public exchange;
    MockToken public tokenA;
    MockToken public tokenB;

    address public owner = address(this);
    address public user = address(0x123);

    function setUp() public {
        tokenA = new MockToken("TokenA", "TKA");
        tokenB = new MockToken("TokenB", "TKB");

        pool = new LiquidityPool(address(tokenA), address(tokenB), owner);
        exchange = new Exchange(address(pool), owner);

        tokenA.mint(user, 1_000 ether);
        tokenB.mint(user, 1_000 ether);

        vm.startPrank(user);
        tokenA.approve(address(pool), type(uint256).max);
        tokenB.approve(address(pool), type(uint256).max);
        tokenA.approve(address(exchange), type(uint256).max);
        tokenB.approve(address(exchange), type(uint256).max);
        vm.stopPrank();
    }

    function testAddLiquidity() public {
        vm.startPrank(user);

        uint256 amountA = 100 ether;
        uint256 amountB = 200 ether;

        uint256 lpTokens = pool.addLiquidity(amountA, amountB);

        assertEq(pool.balanceOf(user), lpTokens, "LP token balance mismatch");

        (uint256 reserveA, uint256 reserveB) = pool.getReserves();
        assertEq(reserveA, amountA, "ReserveA mismatch");
        assertEq(reserveB, amountB, "ReserveB mismatch");

        vm.stopPrank();
    }

    function testRemoveLiquidity() public {
        vm.startPrank(user);

        uint256 amountA = 100 ether;
        uint256 amountB = 200 ether;

        uint256 lpTokens = pool.addLiquidity(amountA, amountB);

        uint256 balanceA = tokenA.balanceOf(user);
        uint256 balanceB = tokenB.balanceOf(user);

        (uint256 removedA, uint256 removedB) = pool.removeLiquidity(lpTokens);

        assertEq(
            tokenA.balanceOf(user),
            balanceA + removedA,
            "TokenA balance mismatch"
        );
        assertEq(
            tokenB.balanceOf(user),
            balanceB + removedB,
            "TokenB balance mismatch"
        );

        (uint256 reserveA, uint256 reserveB) = pool.getReserves();
        assertEq(reserveA, 0, "ReserveA should be zero");
        assertEq(reserveB, 0, "ReserveB should be zero");

        vm.stopPrank();
    }

    function testSwapTokenAToB() public {
        vm.startPrank(user);

        uint256 amountA = 100 ether;
        uint256 amountB = 200 ether;

        pool.addLiquidity(amountA, amountB);

        uint256 swapAmount = 10 ether;
        uint256 tokenBBalanceBefore = tokenB.balanceOf(user);

        uint256 tokenBOut = exchange.swapTokenAToB(swapAmount);

        assert(tokenBOut > 0, "Swap should produce output");

        assertEq(
            tokenB.balanceOf(user),
            tokenBBalanceBefore + tokenBOut,
            "TokenB balance mismatch"
        );

        (uint256 reserveA, uint256 reserveB) = pool.getReserves();

        assertEq(
            reserveA,
            amountA + swapAmount,
            "ReserveA mismatch after swap"
        );
        assertEq(reserveB, amountB - tokenBOut, "ReserveB mismatch after swap");

        vm.stopPrank();
    }

    function testSwapTokenBToA() public {
        vm.startPrank(user);

        uint256 amountA = 100 ether;
        uint256 amountB = 200 ether;

        pool.addLiquidity(amountA, amountB);

        uint256 swapAmount = 10 ether;
        uint256 tokenABalanceBefore = tokenA.balanceOf(user);

        uint256 tokenAOut = exchange.swapTokenBToA(swapAmount);

        assert(tokenAOut > 0, "Swap should produce output");

        assertEq(
            tokenA.balanceOf(user),
            tokenABalanceBefore + tokenAOut,
            "TokenA balance mismatch"
        );

        (uint256 reserveA, uint256 reserveB) = pool.getReserves();

        assertEq(reserveA, amountA - tokenAOut, "ReserveA mismatch after swap");
        assertEq(
            reserveB,
            amountB + swapAmount,
            "ReserveB mismatch after swap"
        );

        vm.stopPrank();
    }

    function testUnauthorizedUpdateReserves() public {
        vm.expectRevert("Unauthorized");
        pool.updateReserves(100, 100);
    }

    function testTransferTokens() public {
        uint256 amount = 50 ether;
        vm.startPrank(user);
        pool.addLiquidity(100 ether, 200 ether);
        vm.stopPrank();

        vm.prank(owner);
        exchange.transferTokens(address(tokenA), user, amount);

        assertEq(tokenA.balanceOf(user), amount, "TokenA transfer mismatch");
    }
}
