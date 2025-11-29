"use client";

import { useState, useEffect } from "react";
import { useAccount, useReadContract, useBalance } from "wagmi";
import { formatUnits, erc20Abi } from "viem";
import { TrendingUp, Loader2, Droplets, Wallet } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
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
      <Card className="max-w-4xl mx-auto shadow-2xl border-2 border-border/50">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <TrendingUp className="h-5 w-5 text-primary" />
            Your Liquidity Positions
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-center py-12 space-y-3">
            <Wallet className="h-12 w-12 mx-auto text-muted-foreground/50" />
            <p className="text-muted-foreground">
              Please connect your wallet to view your liquidity positions.
            </p>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="max-w-4xl mx-auto shadow-2xl border-2 border-border/50">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <TrendingUp className="h-5 w-5 text-primary" />
          Your Liquidity Positions
        </CardTitle>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="text-center py-12 space-y-3">
            <Loader2 className="h-12 w-12 mx-auto text-primary animate-spin" />
            <p className="text-muted-foreground">Loading your positions...</p>
          </div>
        ) : userPools.length > 0 ? (
          <div className="overflow-x-auto">
            <table className="min-w-full">
              <thead>
                <tr className="border-b border-border">
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">
                    Pool
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">
                    Your Liquidity
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">
                    Your Share
                  </th>
                </tr>
              </thead>
              <tbody>
                {userPools.map((pool, index) => (
                  <tr key={index} className="border-b border-border/50 hover:bg-muted/50 transition-colors">
                    <td className="px-4 py-4 whitespace-nowrap">
                      <div className="flex items-center gap-3">
                        <div className="flex-shrink-0 h-10 w-10 relative">
                          <div className="absolute left-0 top-0 h-7 w-7 rounded-full bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center text-white text-xs font-bold shadow-md">
                            {pool.tokenA.symbol.charAt(0)}
                          </div>
                          <div className="absolute right-0 bottom-0 h-7 w-7 rounded-full bg-gradient-to-br from-primary to-primary/60 flex items-center justify-center text-primary-foreground text-xs font-bold shadow-md">
                            {pool.tokenB.symbol.charAt(0)}
                          </div>
                        </div>
                        <div>
                          <div className="text-sm font-semibold">
                            {pool.tokenA.symbol}/{pool.tokenB.symbol}
                          </div>
                          <div className="text-xs text-muted-foreground font-mono">
                            {pool.poolAddress.slice(0, 6)}...{pool.poolAddress.slice(-4)}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-4 whitespace-nowrap">
                      <div className="space-y-1">
                        <div className="text-sm font-medium">
                          {formatUnits(pool.userTokenAAmount, pool.tokenA.decimals).substring(0, 8)}{" "}
                          <span className="text-muted-foreground">{pool.tokenA.symbol}</span>
                        </div>
                        <div className="text-sm font-medium">
                          {formatUnits(pool.userTokenBAmount, pool.tokenB.decimals).substring(0, 8)}{" "}
                          <span className="text-muted-foreground">{pool.tokenB.symbol}</span>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-4 whitespace-nowrap">
                      <div className="space-y-1">
                        <Badge variant="secondary" className="font-semibold">
                          {Number(pool.userShare) / 100}%
                        </Badge>
                        <div className="text-xs text-muted-foreground">
                          {formatUnits(pool.lpBalance.value, 18).substring(0, 8)} LP
                        </div>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : pairAddressStr &&
          pairAddressStr !== "0x0000000000000000000000000000000000000000" ? (
          <div className="text-center py-12 px-4 space-y-4">
            <Droplets className="h-16 w-16 mx-auto text-muted-foreground/30" />
            <div className="space-y-2">
              <p className="text-muted-foreground">
                You don't have any liquidity positions in the {TOKEN_A_SYMBOL}/{TOKEN_B_SYMBOL} pool yet.
              </p>
              <p className="text-sm text-muted-foreground">
                Add liquidity to start earning fees!
              </p>
            </div>
          </div>
        ) : isLoadingPair ? (
          <div className="text-center py-12 space-y-3">
            <Loader2 className="h-12 w-12 mx-auto text-primary animate-spin" />
            <p className="text-muted-foreground">Checking for available pools...</p>
          </div>
        ) : (
          <div className="text-center py-12 px-4 space-y-4">
            <Droplets className="h-16 w-16 mx-auto text-muted-foreground/30" />
            <p className="text-muted-foreground">No liquidity pair exists yet.</p>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
