// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../src/Exchange.sol";
import "../src/LiquidityPool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20("BersensToken", "BTKN") {
        _mint(msg.sender, 1e24); // Mint 1 million tokens
    }
}

contract ExchangeTest is Test {
    LiquidityPool public pool;
    Exchange public exchange;
    MockToken public tokenA;
    MockToken public tokenB;
    address public owner;
    address public user;

    function setUp() public {
        owner = address(this);
        user = address(0x123);

        // Deploy mock tokens
        tokenA = new MockToken("BersensToken", "BTKN");
        tokenB = new MockToken("Etherum", "ETH");

        // Deploy Liquidity Pool
        pool = new LiquidityPool(address(tokenA), address(tokenB), owner);

        // Deploy Exchange
        exchange = new Exchange(address(pool), owner);

        // Fund user with tokens
        tokenA.transfer(user, 1e20);
        tokenB.transfer(user, 1e20);
        console.log("Exchange balance before swap:", tokenB.balanceOf(address(exchange)));

        // Approve tokens for liquidity provision
        vm.prank(user);
        tokenA.approve(address(pool), 1e20);
        vm.prank(user);
        tokenB.approve(address(pool), 1e20);
    }

    function testAddLiquidity() public {
        vm.prank(user);
        uint256 lpMinted = pool.addLiquidity(1e18, 1e18);

        assertGt(lpMinted, 0, "LP tokens should be minted");
        (uint256 reserveA, uint256 reserveB) = pool.getReserves();
        assertEq(reserveA, 1e18, "Reserve A should be updated");
        assertEq(reserveB, 1e18, "Reserve B should be updated");
    }

    function testRemoveLiquidity() public {
        vm.prank(user);
        pool.addLiquidity(1e18, 1e18);

        uint256 lpBalance = pool.balanceOf(user);
        assertGt(lpBalance, 0, "User should have LP tokens");

        vm.prank(user);
        (uint256 amountA, uint256 amountB) = pool.removeLiquidity(lpBalance);

        assertGt(amountA, 0, "User should receive Token A");
        assertGt(amountB, 0, "User should receive Token B");

    }


    function testTokenToEthSwap() public {
        vm.prank(user);
        pool.addLiquidity(1e18, 1e18);

        uint256 tokenAmount = 1e17;
        vm.prank(user);
        tokenA.approve(address(exchange), tokenAmount);

        vm.prank(user);
        uint256 ethReceived = exchange.tokenToEthSwap(tokenAmount);

        assertGt(ethReceived, 0, "ETH should be received from swap");
    }

    function testEthToTokens() public {
        vm.prank(user);
        pool.addLiquidity(1e18, 1e18);

        vm.deal(user, 1e18); // Give user 1 ETH

        vm.prank(user);
        uint256 tokensReceived = exchange.ethToTokens{value: 1e17}();

        assertGt(tokensReceived, 0, "Tokens should be received from swap");
    }
}
