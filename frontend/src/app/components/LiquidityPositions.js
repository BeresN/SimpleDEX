"use client";

import { useState, useEffect } from "react";
import { useAccount, useReadContract, useBalance } from "wagmi";
import { formatUnits, erc20Abi } from "viem";
import factoryAbi from "../../../abis/factoryAbi.json";
import liquidityPoolAbi from "../../../abis/liquidityPoolAbi.json";
import { useRouter } from "next/navigation";

// Assuming you have a factory contract that manages all liquidity pools
const FACTORY_ADDRESS = "0x39D59a27a78E15ed245E3706c5eCFEc0131A6B45";
const LIQUIDITY_POOL_ADDRESS = "0xBAD4F032cC2Fd09b0C71B2D3336dD4A6beF724a7";
const TOKEN_A_ADDRESS = "0x558f6e1BFfD83AD9F016865bF98D6763566d49c6";
const TOKEN_B_ADDRESS = "0x4DF4493209006683e678983E1Ec097680AB45e13";
const TOKEN_A_SYMBOL = "mETH";
const TOKEN_B_SYMBOL = "mSEI";

export default function LiquidityPositions() {
  const { address, isConnected } = useAccount();
  const [userPools, setUserPools] = useState([]);
  const [isLoading, setIsLoading] = useState(false);
  const router = useRouter();

  // Read data from the factory contract
  const { data: pairAddress, isLoading: isLoadingPair } = useReadContract({
    address: FACTORY_ADDRESS,
    abi: factoryAbi,
    functionName: "getPairAddress",
    args: [TOKEN_A_ADDRESS, TOKEN_B_ADDRESS],
    enabled: isConnected,
  });

  const pairAddressStr = pairAddress ? String(pairAddress) : "";

  // Get LP Token balance
  const { data: lpBalance, refetch: refetchLpBalance } = useBalance({
    address,
    token: LIQUIDITY_POOL_ADDRESS,
    watch: true,
    enabled: isConnected && !!LIQUIDITY_POOL_ADDRESS,
  });

  // Get reserves
  const { data: reserves, refetch: refetchReserves } = useReadContract({
    address: LIQUIDITY_POOL_ADDRESS,
    abi: liquidityPoolAbi,
    functionName: "getReserves",
    enabled: isConnected && !!LIQUIDITY_POOL_ADDRESS,
  });

  // Get total supply of LP tokens
  const { data: totalSupply } = useReadContract({
    address: LIQUIDITY_POOL_ADDRESS,
    abi: liquidityPoolAbi,
    functionName: "totalSupply",
    enabled: isConnected && !!LIQUIDITY_POOL_ADDRESS,
  });

  useEffect(() => {
    if (
      isConnected &&
      pairAddressStr &&
      pairAddressStr !== "" &&
      pairAddressStr !== "0x0000000000000000000000000000000000000000"
    ) {
      fetchUserPools();
    } else {
      setIsLoading(false);
    }
  }, [isConnected, pairAddressStr, lpBalance]);

  const fetchUserPools = async () => {
    try {
      setIsLoading(true);
      console.log("Fetching user pools...");

      if (!lpBalance || !reserves || !totalSupply) {
        console.log("Missing data to calculate position");
        setUserPools([]);
        setIsLoading(false);
        return;
      }

      const userShare = (lpBalance.value * BigInt(10000)) / totalSupply;

      const userTokenAAmount = (reserves[0] * lpBalance.value) / totalSupply;
      const userTokenBAmount = (reserves[1] * lpBalance.value) / totalSupply;

      if (lpBalance.value > BigInt(0)) {
        const newPool = {
          poolAddress: LIQUIDITY_POOL_ADDRESS,
          tokenA: {
            address: TOKEN_A_ADDRESS,
            symbol: TOKEN_A_SYMBOL,
            decimals: 18,
          },
          tokenB: {
            address: TOKEN_B_ADDRESS,
            symbol: TOKEN_B_SYMBOL,
            decimals: 18,
          },
          userTokenAAmount,
          userTokenBAmount,
          userShare,
          lpBalance,
        };

        setUserPools([newPool]);
      } else {
        setUserPools([]);
      }

      setIsLoading(false);
    } catch (error) {
      console.error("Error fetching user pools:", error);
      setIsLoading(false);
    }
  };

  if (!isConnected) {
    return (
      <div className="bg-gray-800 rounded-2xl p-4 sm:p-5 max-w-4xl mx-auto mt-8 text-white border border-gray-700 shadow-lg">
        <div className="flex justify-between items-center mb-5">
          <h2 className="text-xl font-bold">Your Liquidity Positions</h2>
        </div>
        <div className="text-center text-gray-400 py-8">
          Please connect your wallet to view your liquidity positions.
        </div>
      </div>
    );
  }

  return (
    <div className="bg-gray-800 rounded-2xl p-4 sm:p-5 max-w-4xl mx-auto mt-8 text-white border border-gray-700 shadow-lg">
      <div className="flex justify-between items-center mb-5">
        <h2 className="text-xl font-bold">Your Liquidity Positions</h2>
      </div>

      {isLoading ? (
        <div className="text-center py-10">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-emerald-500 mb-4"></div>
          <p className="text-gray-400">Loading your positions...</p>
        </div>
      ) : userPools.length > 0 ? (
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-700">
            <thead>
              <tr>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                  Pool
                </th>
                <th className="px-4 py-3 text-middle text-xs font-medium text-gray-400 uppercase tracking-wider">
                  Your Liquidity
                </th>
                <th className="px-4 py-3 text-middle text-xs font-medium text-gray-400 uppercase tracking-wider">
                  Your Share
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-700">
              {userPools.map((pool, index) => (
                <tr key={index} className="hover:bg-gray-700">
                  <td className="px-4 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      <div className="flex-shrink-0 h-8 w-8 relative">
                        <div className="absolute left-0 top-0 h-6 w-6 rounded-full bg-blue-500 flex items-center justify-center">
                          {pool.tokenA.symbol.charAt(0)}
                        </div>
                        <div className="absolute right-0 bottom-0 h-6 w-6 rounded-full bg-green-500 flex items-center justify-center">
                          {pool.tokenB.symbol.charAt(0)}
                        </div>
                      </div>
                      <div className="ml-4">
                        <div className="text-sm font-medium">
                          {pool.tokenA.symbol}/{pool.tokenB.symbol}
                        </div>
                        <div className="text-xs text-gray-400">
                          {pool.poolAddress.slice(0, 6)}...
                          {pool.poolAddress.slice(-4)}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td className="px-4 py-4 whitespace-nowrap">
                    <div className="text-sm">
                      {formatUnits(
                        pool.userTokenAAmount,
                        pool.tokenA.decimals,
                      ).substring(0, 8)}{" "}
                      {pool.tokenA.symbol}
                    </div>
                    <div className="text-sm">
                      {formatUnits(
                        pool.userTokenBAmount,
                        pool.tokenB.decimals,
                      ).substring(0, 8)}{" "}
                      {pool.tokenB.symbol}
                    </div>
                  </td>
                  <td className="px-4 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium">
                      {Number(pool.userShare) / 100}%
                    </div>
                    <div className="text-xs text-gray-400">
                      {formatUnits(pool.lpBalance.value, 18).substring(0, 8)} LP
                      Tokens
                    </div>
                  </td>
                  <td className="px-4 py-4 whitespace-nowrap text-sm"> </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : pairAddressStr &&
        pairAddressStr !== "0x0000000000000000000000000000000000000000" ? (
        <div className="text-center py-10 px-4">
          <div className="text-gray-400 mb-6">
            <p>
              You don't have any liquidity positions in the {TOKEN_A_SYMBOL}/
              {TOKEN_B_SYMBOL} pool yet.
            </p>
            <p className="mt-2">Add liquidity to start earning fees!</p>
          </div>
        </div>
      ) : isLoadingPair ? (
        <div className="text-center py-10">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-emerald-500 mb-4"></div>
          <p className="text-gray-400">Checking for available pools...</p>
        </div>
      ) : (
        <div className="text-center py-10 px-4">
          <div className="text-gray-400 mb-6">
            <p>No liquidity pair exists yet.</p>
          </div>
        </div>
      )}
    </div>
  );
}
