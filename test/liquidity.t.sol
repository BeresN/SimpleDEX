// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../src/LiquidityPool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract LiquidityPoolTest is Test {
    LiquidityPool public pool;
    MockERC20 public tokenA;
    MockERC20 public tokenB;
    address public exchangeAddress = address(0x123);

    address user = address(0x456);

    function setUp() public {
        tokenA = new MockERC20("TokenA", "TKA");
        tokenB = new MockERC20("TokenB", "TKB");

        pool = new LiquidityPool(
            address(tokenA),
            address(tokenB),
            exchangeAddress
        );

        tokenA.mint(user, 1_000 ether);
        tokenB.mint(user, 1_000 ether);

        vm.prank(user);
        tokenA.approve(address(pool), type(uint256).max);
        vm.prank(user);
        tokenB.approve(address(pool), type(uint256).max);
    }

    function testAddLiquidity() public {
        vm.prank(user);
        pool.addLiquidity(100 ether, 100 ether);

        (uint256 reserveA, uint256 reserveB) = pool.getReserves();
        assertEq(reserveA, 100 ether, "Reserve A mismatch");
        assertEq(reserveB, 100 ether, "Reserve B mismatch");

        uint256 lpBalance = pool.balanceOf(user);
        assertGt(lpBalance, 0, "LP Tokens not minted");
    }

    function testRemoveLiquidity() public {
        vm.prank(user);
        pool.addLiquidity(100 ether, 100 ether);

        uint256 lpBalance = pool.balanceOf(user);

        vm.prank(user);
        pool.removeLiquidity(lpBalance);

        (uint256 reserveA, uint256 reserveB) = pool.getReserves();

        assertEq(reserveA, 0, "Reserve A should be zero");
        assertEq(reserveB, 0, "Reserve B should be zero");

        assertEq(pool.balanceOf(user), 0, "LP Tokens not burned");
    }

    function testAddLiquidityWithZeroAmount() public {
        vm.expectRevert("Must be more than 0");
        vm.prank(user);
        pool.addLiquidity(0, 0);
    }

    function testRemoveLiquidityWithZeroAmount() public {
        vm.prank(user);
        pool.addLiquidity(100 ether, 100 ether);

        vm.expectRevert("Amount must be greater than zero");
        vm.prank(user);
        pool.removeLiquidity(0);
    }

    function testUnauthorizedReserveUpdate() public {
        vm.expectRevert("Unauthorized");
        pool.updateReserves(200 ether, 200 ether);
    }

    function testAuthorizedReserveUpdate() public {
        vm.prank(exchangeAddress);
        pool.updateReserves(200 ether, 200 ether);

        (uint256 reserveA, uint256 reserveB) = pool.getReserves();

        assertEq(reserveA, 200 ether, "Reserve A mismatch");
        assertEq(reserveB, 200 ether, "Reserve B mismatch");
    }
}
