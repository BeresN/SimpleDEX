// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/LiquidityPool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function approveMax(address spender) external {
        _approve(msg.sender, spender, type(uint256).max);
    }
}

contract LiquidityPoolTest is Test {
    LiquidityPool public pool;
    MockERC20 public tokenA;
    MockERC20 public tokenB;
    address public user;

    function setUp() public {
        tokenA = new MockERC20("Token A", "TKNA");
        tokenB = new MockERC20("Token B", "TKNB");

        pool = new LiquidityPool(address(tokenA), address(tokenB));
        user = address(0x123);

        tokenA.mint(user, 1000 * 10 ** 18);
        tokenB.mint(user, 1000 * 10 ** 18);

        vm.startPrank(user);
        tokenA.approve(address(pool), type(uint256).max);
        tokenB.approve(address(pool), type(uint256).max);
        vm.stopPrank();
    }

    function testAddLiquidity() public {
        vm.startPrank(user);

        uint256 amountA = 100 * 10 ** 18;
        uint256 amountB = 100 * 10 ** 18;

        uint256 beforeA = tokenA.balanceOf(user);
        uint256 beforeB = tokenB.balanceOf(user);

        vm.expectEmit(true, true, true, true);
        emit LiquidityAdded(user, amountA, amountB, 10 ** 18);
        uint256 lpMinted = pool.addLiquidity(amountA, amountB);

        uint256 afterA = tokenA.balanceOf(user);
        uint256 afterB = tokenB.balanceOf(user);
        uint256 lpBalance = pool.lpTokens(user);

        assertEq(beforeA - afterA, amountA, "Token A should be deducted");
        assertEq(beforeB - afterB, amountB, "Token B should be deducted");
        assertEq(lpBalance, lpMinted, "LP tokens should be minted");
        vm.stopPrank();
    }

    function testRemoveLiquidity() public {
        vm.startPrank(user);

        uint256 amountA = 100 * 10 ** 18;
        uint256 amountB = 100 * 10 ** 18;
        pool.addLiquidity(amountA, amountB);

        uint256 lpBalance = pool.lpTokens(user);
        assertGt(lpBalance, 0, "LP tokens should be minted");

        uint256 beforeA = tokenA.balanceOf(user);
        uint256 beforeB = tokenB.balanceOf(user);

        vm.expectEmit(true, true, true, true);
        emit LiquidityRemoved(user, amountA / 2, amountB / 2, lpBalance / 2);
        (uint256 amountARemoved, uint256 amountBRemoved) = pool.removeLiquidity(
            lpBalance / 2
        );

        uint256 afterA = tokenA.balanceOf(user);
        uint256 afterB = tokenB.balanceOf(user);

        assertEq(
            afterA,
            beforeA + amountARemoved,
            "User should get back Token A"
        );
        assertEq(
            afterB,
            beforeB + amountBRemoved,
            "User should get back Token B"
        );

        uint256 newLpBalance = pool.lpTokens(user);
        assertEq(
            newLpBalance,
            lpBalance - lpBalance / 2,
            "LP tokens should be reduced"
        );
        vm.stopPrank();
    }
}
