// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../../src/Factory.sol";
import "../../src/Pair.sol";
import "../mocks/MockERC20.sol";

contract FactoryTest is Test {
    Factory public factory;
    MockERC20 public tokenA;
    MockERC20 public tokenB;
    MockERC20 public tokenC;

    address public owner = address(1);
    address public user = address(2);

    event PairCreated(
        address token0,
        address token1,
        address pair,
        uint totalPairs
    );

    event OwnerChanged(address newOwner);

    function setUp() public {
        vm.startPrank(owner);

        // Deploy factory
        factory = new Factory(owner);

        // Deploy mock tokens with different addresses to ensure ordering works
        tokenA = new MockERC20("Token A", "TKA", 18);
        tokenB = new MockERC20("Token B", "TKB", 18);
        tokenC = new MockERC20("Token C", "TKC", 18);

        vm.stopPrank();
    }

    // ============================================
    // PAIR CREATION TESTS
    // ============================================

    function test_CreateNewPair_Success() public {
        vm.prank(owner);
        address pair = factory.CreateNewPair(address(tokenA), address(tokenB));

        assertNotEq(pair, address(0), "Pair address should not be zero");
        assertTrue(pair != address(0), "Pair should be created");
    }

    function test_CreateNewPair_RevertsOnDuplicates() public {
        vm.startPrank(owner);

        // Create first pair
        factory.CreateNewPair(address(tokenA), address(tokenB));

        // Try to create duplicate
        vm.expectRevert("PAIR ALREADY EXISTS");
        factory.CreateNewPair(address(tokenA), address(tokenB));

        vm.stopPrank();
    }

    function test_CreateNewPair_RevertsOnDuplicatesReverseOrder() public {
        vm.startPrank(owner);

        // Create first pair with A, B
        factory.CreateNewPair(address(tokenA), address(tokenB));

        // Try to create duplicate with B, A (reverse order)
        vm.expectRevert("PAIR ALREADY EXISTS");
        factory.CreateNewPair(address(tokenB), address(tokenA));

        vm.stopPrank();
    }

    function test_CreateNewPair_TokenOrderingConsistent() public {
        vm.prank(owner);
        address pair1 = factory.CreateNewPair(address(tokenA), address(tokenB));

        // Verify same pair address regardless of input order
        address retrievedPair1 = factory.getPairAddress(address(tokenA), address(tokenB));
        address retrievedPair2 = factory.getPairAddress(address(tokenB), address(tokenA));

        assertEq(pair1, retrievedPair1, "Pair address should match");
        assertEq(retrievedPair1, retrievedPair2, "Pair address should be same regardless of token order");
    }

    function test_CreateNewPair_EmitsCorrectEvent() public {
        // Determine correct token order
        (address token0, address token1) = address(tokenA) < address(tokenB)
            ? (address(tokenA), address(tokenB))
            : (address(tokenB), address(tokenA));

        vm.prank(owner);

        // Expect event with ordered tokens
        vm.expectEmit(true, true, false, true);
        emit PairCreated(token0, token1, address(0), 1); // address(0) as placeholder for pair

        factory.CreateNewPair(address(tokenA), address(tokenB));
    }

    function test_CreateNewPair_IncrementsPairCount() public {
        assertEq(factory.allPairsLength(), 0, "Initial pair count should be 0");

        vm.startPrank(owner);

        factory.CreateNewPair(address(tokenA), address(tokenB));
        assertEq(factory.allPairsLength(), 1, "Pair count should be 1");

        factory.CreateNewPair(address(tokenA), address(tokenC));
        assertEq(factory.allPairsLength(), 2, "Pair count should be 2");

        factory.CreateNewPair(address(tokenB), address(tokenC));
        assertEq(factory.allPairsLength(), 3, "Pair count should be 3");

        vm.stopPrank();
    }

    function test_CreateNewPair_RevertsOnSameToken() public {
        vm.prank(owner);
        vm.expectRevert("SAME TOKENS!");
        factory.CreateNewPair(address(tokenA), address(tokenA));
    }

    function test_CreateNewPair_RevertsOnZeroAddressFirst() public {
        vm.prank(owner);
        vm.expectRevert("CANNOT BE ADDRESS 0!");
        factory.CreateNewPair(address(0), address(tokenA));
    }

    function test_CreateNewPair_RevertsOnZeroAddressSecond() public {
        vm.prank(owner);
        vm.expectRevert("CANNOT BE ADDRESS 0!");
        factory.CreateNewPair(address(tokenA), address(0));
    }

    function test_CreateNewPair_RevertsOnBothZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert("SAME TOKENS!");
        factory.CreateNewPair(address(0), address(0));
    }

    function test_CreateNewPair_OnlyOwner() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user));
        factory.CreateNewPair(address(tokenA), address(tokenB));
    }

    // ============================================
    // GETTER TESTS
    // ============================================

    function test_GetPairAddress_ReturnsCorrectAddress() public {
        vm.prank(owner);
        address createdPair = factory.CreateNewPair(address(tokenA), address(tokenB));

        address retrievedPair = factory.getPairAddress(address(tokenA), address(tokenB));

        assertEq(retrievedPair, createdPair, "Retrieved pair should match created pair");
    }

    function test_GetPairAddress_OrderIndependent() public {
        vm.prank(owner);
        address createdPair = factory.CreateNewPair(address(tokenA), address(tokenB));

        address pair1 = factory.getPairAddress(address(tokenA), address(tokenB));
        address pair2 = factory.getPairAddress(address(tokenB), address(tokenA));

        assertEq(pair1, pair2, "Pair address should be same regardless of order");
        assertEq(pair1, createdPair, "Both should match created pair");
    }

    function test_GetPairAddress_ReturnsZeroForNonexistent() public {
        address pair = factory.getPairAddress(address(tokenA), address(tokenB));
        assertEq(pair, address(0), "Non-existent pair should return zero address");
    }

    function test_GetPair_MappingBothDirections() public {
        vm.prank(owner);
        address createdPair = factory.CreateNewPair(address(tokenA), address(tokenB));

        // Determine token order
        (address token0, address token1) = address(tokenA) < address(tokenB)
            ? (address(tokenA), address(tokenB))
            : (address(tokenB), address(tokenA));

        // Check both directions in mapping
        assertEq(factory.getPair(token0, token1), createdPair, "Forward mapping should work");
        assertEq(factory.getPair(token1, token0), createdPair, "Reverse mapping should work");
    }

    function test_AllPairsLength_ReturnsCorrectCount() public {
        assertEq(factory.allPairsLength(), 0, "Initial count should be 0");

        vm.startPrank(owner);

        factory.CreateNewPair(address(tokenA), address(tokenB));
        assertEq(factory.allPairsLength(), 1);

        factory.CreateNewPair(address(tokenB), address(tokenC));
        assertEq(factory.allPairsLength(), 2);

        vm.stopPrank();
    }

    function test_AllTokenPairs_ArrayStoredCorrectly() public {
        vm.startPrank(owner);

        address pair1 = factory.CreateNewPair(address(tokenA), address(tokenB));
        address pair2 = factory.CreateNewPair(address(tokenA), address(tokenC));

        assertEq(factory.allTokenPairs(0), pair1, "First pair in array should match");
        assertEq(factory.allTokenPairs(1), pair2, "Second pair in array should match");

        vm.stopPrank();
    }

    // ============================================
    // OWNERSHIP TESTS
    // ============================================

    function test_OwnerAddressChange_EmitsEvent() public {
        address newOwner = address(3);

        vm.expectEmit(true, false, false, true);
        emit OwnerChanged(newOwner);

        factory.OwnerAddressChange(newOwner);
    }

    function test_OwnerAddressChange_RevertsOnZeroAddress() public {
        vm.expectRevert("CANNOT BE ADDRESS 0!");
        factory.OwnerAddressChange(address(0));
    }

    function test_OwnerAddressChange_ReturnsNewOwner() public {
        address newOwner = address(3);
        address returnedOwner = factory.OwnerAddressChange(newOwner);

        assertEq(returnedOwner, newOwner, "Should return new owner address");
    }

    // Note: OwnerAddressChange doesn't actually change ownership, it just emits event
    // This is a bug in the contract - it should call transferOwnership

    // ============================================
    // FUZZ TESTS
    // ============================================

    function testFuzz_CreatePair_WithRandomTokens(address token1, address token2) public {
        // Filter invalid inputs
        vm.assume(token1 != token2);
        vm.assume(token1 != address(0));
        vm.assume(token2 != address(0));
        vm.assume(token1.code.length == 0); // Ensure not a contract
        vm.assume(token2.code.length == 0);

        vm.prank(owner);
        address pair = factory.CreateNewPair(token1, token2);

        assertTrue(pair != address(0), "Pair should be created");
        assertEq(factory.allPairsLength(), 1, "Should have one pair");
    }

    function testFuzz_GetPairAddress_OrderIndependent(address token1, address token2) public {
        // Filter invalid inputs
        vm.assume(token1 != token2);
        vm.assume(token1 != address(0));
        vm.assume(token2 != address(0));
        vm.assume(token1.code.length == 0);
        vm.assume(token2.code.length == 0);

        vm.prank(owner);
        factory.CreateNewPair(token1, token2);

        address pair1 = factory.getPairAddress(token1, token2);
        address pair2 = factory.getPairAddress(token2, token1);

        assertEq(pair1, pair2, "Pair address should be order-independent");
    }

    // ============================================
    // INTEGRATION-LIKE TESTS
    // ============================================

    function test_CreateMultiplePairs_AllAccessible() public {
        vm.startPrank(owner);

        address pairAB = factory.CreateNewPair(address(tokenA), address(tokenB));
        address pairAC = factory.CreateNewPair(address(tokenA), address(tokenC));
        address pairBC = factory.CreateNewPair(address(tokenB), address(tokenC));

        assertEq(factory.getPairAddress(address(tokenA), address(tokenB)), pairAB);
        assertEq(factory.getPairAddress(address(tokenA), address(tokenC)), pairAC);
        assertEq(factory.getPairAddress(address(tokenB), address(tokenC)), pairBC);
        assertEq(factory.allPairsLength(), 3);

        vm.stopPrank();
    }

    function test_CreatedPair_IsValidContract() public {
        vm.prank(owner);
        address pairAddress = factory.CreateNewPair(address(tokenA), address(tokenB));

        // Verify it's a contract
        uint256 size;
        assembly {
            size := extcodesize(pairAddress)
        }
        assertTrue(size > 0, "Pair should be a contract");

        // Verify it's a Pair contract by calling getReserves
        Pair pair = Pair(pairAddress);
        (uint256 reserveA, uint256 reserveB) = pair.getReserves();
        assertEq(reserveA, 0, "Initial reserve A should be 0");
        assertEq(reserveB, 0, "Initial reserve B should be 0");
    }
}
