"use client";

import { useState, useEffect } from "react";
import { useAccount, useReadContract, useBalance } from "wagmi";
import { formatUnits } from "viem";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import factoryAbi from "../../../abis/factoryAbi.json";
import liquidityPoolAbi from "../../../abis/liquidityPoolAbi.json";

// Assuming you have a factory contract that manages all liquidity pools
const FACTORY_ADDRESS = "0x64078611768BCb3aBa5f34F6390e57ccA3652BE7";
const LIQUIDITY_POOL_ADDRESS = "0xBAD4F032cC2Fd09b0C71B2D3336dD4A6beF724a7";
const TOKEN_A_SYMBOL = "mETH";
const TOKEN_B_SYMBOL = "mSEI";

export default function LiquidityPositions() {
  const { address, isConnected } = useAccount();
  const [userPools, setUserPools] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

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

      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-700">
          <thead>
            <tr>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                Pool
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                Your Liquidity
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                Your Share
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                Actions
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
                        {pool.poolAddress.substring(0, 6)}...
                        {pool.poolAddress.substring(
                          pool.poolAddress.length - 4
                        )}
                      </div>
                    </div>
                  </div>
                </td>
                <td className="px-4 py-4 whitespace-nowrap">
                  <div className="text-sm">
                    {formatUnits(pool.userTokenAAmount, pool.tokenA.decimals)}{" "}
                    {pool.tokenA.symbol}
                  </div>
                  <div className="text-sm">
                    {formatUnits(pool.userTokenBAmount, pool.tokenB.decimals)}{" "}
                    {pool.tokenB.symbol}
                  </div>
                </td>
                <td className="px-4 py-4 whitespace-nowrap">
                  <div className="text-sm font-medium">
                    {Number(pool.userShare) / 100}%
                  </div>
                  <div className="text-xs text-gray-400">
                    {formatUnits(pool.lpBalance.value, 18)} LP Tokens
                  </div>
                </td>
                <td className="px-4 py-4 whitespace-nowrap text-sm">
                  <button
                    onClick={() => handleRemoveLiquidity(pool.poolAddress)}
                    className="px-3 py-1 bg-red-600 hover:bg-red-700 rounded-lg text-white text-xs"
                  >
                    Remove
                  </button>
                  <button
                    onClick={() => handleAddMoreLiquidity(pool.poolAddress)}
                    className="ml-2 px-3 py-1 bg-emerald-600 hover:bg-emerald-700 rounded-lg text-white text-xs"
                  >
                    Add More
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
