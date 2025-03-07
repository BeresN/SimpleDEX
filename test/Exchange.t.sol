// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/LiquidityPool.sol";
import "../src/Exchange.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 100000 * 10 ** decimals());
    }
}

contract LiquidityPoolTest is Test {
    MockERC20 tokenA;
    MockERC20 tokenB;
    MockERC20 lpTokens;

    LiquidityPool pool;
    Exchange exchange;

    address owner = address(0x123);
    address user = address(0x456);

    function setUp() public {
        // Deploy mock tokens
        tokenA = new MockERC20("TokenA", "TKA");
        tokenB = new MockERC20("TokenB", "TKB");
        lpTokens = new MockERC20("lpTOkens", "LPTK");

        // Deploy Liquidity Pool and Exchange
        pool = new LiquidityPool(
            address(tokenA),
            address(tokenB),
            address(this)
        );
        exchange = new Exchange(address(pool), address(this));

        // Approve pool to spend tokens on behalf of this contract
        tokenA.approve(address(pool), type(uint256).max);
        tokenB.approve(address(pool), type(uint256).max);

        // Approve exchange to spend tokens
        tokenA.approve(address(exchange), type(uint256).max);
        tokenB.approve(address(exchange), type(uint256).max);
    }
    function testAddLiquidity() public {
        uint256 lpMinted = pool.addLiquidity(100 ether, 100 ether);
        assertEq(lpMinted, 100 ether);

        (uint256 reserveA, uint256 reserveB) = pool.getReserves();
        assertEq(reserveA, 100 ether);
        assertEq(reserveB, 100 ether);
    }

    function testRemoveLiquidity() public {
        pool.addLiquidity(100 ether, 100 ether);
        pool.approve(address(pool), pool.balanceOf(address(this)));
        uint256 lpBalance = 100 ether;
        (uint256 reserveA, uint256 reserveB) = pool.getReserves();

        console.log("LP to Burn: ", lpBalance);
        console.log("Reserve A: ", reserveA);
        console.log("Reserve B: ", reserveB);
        pool.removeLiquidity(lpBalance);

        console.log("LP to Burn: ", lpBalance);
        console.log("Reserve A: ", reserveA);
        console.log("Reserve B: ", reserveB);
        assertEq(reserveA, 0);
        assertEq(reserveB, 0);

        assertEq(tokenA.balanceOf(address(this)), 100 ether);
        assertEq(tokenB.balanceOf(address(this)), 100 ether);
    }

    function testSwapTokenAToB() public {
        pool.addLiquidity(100 ether, 100 ether);

        tokenA.approve(address(exchange), 10 ether);

        uint256 tokenBReceived = exchange.swapTokenAToB(10 ether);

        assertGt(tokenBReceived, 0);

        (uint256 reserveA, uint256 reserveB) = pool.getReserves();
        assertEq(reserveA, 110 ether);
        assertEq(reserveB, 90 ether);
    }

    function testSwapTokenBToA() public {
        pool.addLiquidity(100 ether, 100 ether);

        tokenB.approve(address(exchange), 10 ether);

        uint256 tokenAReceived = exchange.swapTokenBToA(10 ether);

        assertGt(tokenAReceived, 0);

        (uint256 reserveA, uint256 reserveB) = pool.getReserves();
        assertEq(reserveA, 90 ether);
        assertEq(reserveB, 110 ether);
    }

    function testUnauthorizedReserveUpdate() public {
        vm.expectRevert("Unauthorized");
        pool.updateReserves(500 ether, 500 ether);
    }
}
