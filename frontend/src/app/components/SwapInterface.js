"use client";

import { useState, useEffect } from "react";
import {
  useAccount,
  useBalance,
  useReadContract,
  useWriteContract,
  useWaitForTransactionReceipt,
} from "wagmi";
import { parseUnits, formatUnits } from "viem";
import { erc20Abi } from "viem";
import { ArrowDownUp, Loader2 } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import TokenSelector from "@/components/TokenSelector";
import "tailwindcss";
import swapAbi from "../../../abis/swapAbi.json";

const TOKEN_A_ADDRESS = "0x558f6e1BFfD83AD9F016865bF98D6763566d49c6";
const TOKEN_B_ADDRESS = "0x4DF4493209006683e678983E1Ec097680AB45e13";
const SWAP_CONTRACT_ADDRESS = "0xBAD4F032cC2Fd09b0C71B2D3336dD4A6beF724a7";
const TOKEN_A_SYMBOL = "mETH";
const TOKEN_B_SYMBOL = "mSEI";
const MaxUint256 = BigInt(
  "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
);

export default function SwapInterface() {
  const [fromToken, setFromToken] = useState(TOKEN_A_SYMBOL);
  const [toToken, setToToken] = useState(TOKEN_B_SYMBOL);
  const [fromAmount, setFromAmount] = useState("");
  const [toAmount, setToAmount] = useState("");

  const { address, isConnected } = useAccount();

  const { data: balanceA, isLoading: isLoadingBalanceA } = useBalance({
    address,
    token: TOKEN_A_ADDRESS,
    watch: true,
  });

  const { data: balanceB, isLoading: isLoadingBalanceB } = useBalance({
    address,
    token: TOKEN_B_ADDRESS,
    watch: true,
  });

  const { data: balanceLP, isLoading: isLoadingBalanceLP } = useBalance({
    address,
    token: SWAP_CONTRACT_ADDRESS,
    watch: true,
  });

  const { data: reserves, refetch: refetchReserves } = useReadContract({
    address: SWAP_CONTRACT_ADDRESS,
    abi: swapAbi,
    functionName: "getReserves",
    enabled: isConnected && !!address,
  });

  const reserveA = reserves?.[0];
  const reserveB = reserves?.[1];

  const fromTokenAddress =
    fromToken === TOKEN_A_SYMBOL ? TOKEN_A_ADDRESS : TOKEN_B_ADDRESS;
  const fromTokenBalance = fromToken === TOKEN_A_SYMBOL ? balanceA : balanceB;

  const { data: allowance, refetch: refetchAllowance } = useReadContract({
    address: fromTokenAddress,
    abi: erc20Abi,
    functionName: "allowance",
    args: [address, SWAP_CONTRACT_ADDRESS],
    enabled: isConnected && !!address,
  });

  const {
    data: approveData,
    writeContractAsync: approveTx,
    isPending: isApproving,
    error: approveError,
  } = useWriteContract();

  const {
    data: swapData,
    writeContractAsync: swapTx,
    isPending: isSwapping,
    error: swapError,
  } = useWriteContract();

  const { isLoading: isConfirmingApprove, isSuccess: isSuccessApprove } =
    useWaitForTransactionReceipt({ hash: approveData?.hash });

  const { isLoading: isConfirmingSwap, isSuccess: isSuccessSwap } =
    useWaitForTransactionReceipt({ hash: swapData?.hash });

  const needsApproval = () => {
    if (!isConnected || !fromAmount || !fromTokenBalance || !allowance)
      return false;
    try {
      const amountWei = parseUnits(fromAmount, fromTokenBalance.decimals);
      return allowance < amountWei;
    } catch {
      return false;
    }
  };

  const isProcessing =
    isApproving || isConfirmingApprove || isSwapping || isConfirmingSwap;

  const handleSwapTokens = () => {
    setFromToken(toToken);
    setToToken(fromToken);
    setFromAmount(toAmount);
    setToAmount(fromAmount);
  };

  const handleApprove = async () => {
    if (!isConnected || !fromAmount) return;
    try {
      const tx = await approveTx({
        address: fromTokenAddress,
        abi: erc20Abi,
        functionName: "approve",
        args: [SWAP_CONTRACT_ADDRESS, MaxUint256],
      });

      const receipt = await waitForTransaction({ hash: tx.hash });
      console.log("Approval confirmed:", receipt);

      await refetchAllowance();
    } catch (err) {
      console.error("Failed to approve:", err);
    }
  };

  const handleSwap = async () => {
    if (!isConnected || !fromAmount || needsApproval()) return;
    try {
      const amountWei = parseUnits(fromAmount, fromTokenBalance.decimals);

      // Determine which token is being swapped from
      const amountAIn = fromToken === TOKEN_A_SYMBOL ? amountWei : 0n;
      const amountBIn = fromToken === TOKEN_B_SYMBOL ? amountWei : 0n;
      if (balanceLP < amountAIn) {
        console.log("insufficient Amount of LP, add liquidity", balanceLP);
      }

      console.log("Swapping with:", {
        amountAIn: amountAIn.toString(),
        amountBIn: amountBIn.toString(),
        to: address,
      });

      await swapTx({
        address: SWAP_CONTRACT_ADDRESS,
        abi: swapAbi,
        functionName: "swap",
        args: [amountAIn, amountBIn, address],
      });
    } catch (err) {
      console.error("Swap failed:", err);
      // Display detailed error to user
      alert(`Swap failed: ${err.message}`);
    }
  };

  const handleFromAmountChange = (e) => {
    const value = e.target.value;
    if (/^\d*\.?\d*$/.test(value)) {
      setFromAmount(value);
      // Mock price calculation
      setToAmount(value * (fromToken === TOKEN_A_SYMBOL ? 1 : 1 / 2));
    }
  };

  const checkReserves = async () => {
    try {
      await refetchReserves(); // This triggers a refetch
      // Use the reserves from the hook
      if (reserves) {
        console.log("Current Reserves:", {
          reserveA: formatUnits(reserves[0], 18),
          reserveB: formatUnits(reserves[1], 18),
        });
        return reserves;
      } else {
        console.log("No reserves data available");
        return null;
      }
    } catch (error) {
      console.error("Error checking reserves:", error);
      return null;
    }
  };

  // Add useEffect to monitor reserves
  useEffect(() => {
    if (isConnected && reserves) {
      console.log("Reserves updated:", {
        reserveA: formatUnits(reserves[0], 18),
        reserveB: formatUnits(reserves[1], 18),
      });
    }
  }, [reserves, isConnected]);

  // Modify your handleAddLiquidity function
  const handleAddLiquidity = async () => {
    if (!isConnected || !fromAmount) return;

    try {
      // Check reserves before
      console.log("Reserves before adding liquidity:");
      const reservesBefore = await checkReserves();

      // Your existing add liquidity logic
      const amountWei = parseUnits(fromAmount, fromTokenBalance.decimals);
      const tx = await addLiquidityTx({
        address: SWAP_CONTRACT_ADDRESS,
        abi: swapAbi,
        functionName: "addLiquidity",
        args: [amountWei, amountWei], // Adjust args as needed
      });

      // Wait for transaction
      const receipt = await waitForTransaction({ hash: tx.hash });

      // Check reserves after
      console.log("Reserves after adding liquidity:");
      const reservesAfter = await checkReserves();

      // Log the difference
      if (reservesBefore && reservesAfter) {
        console.log("Reserve changes:", {
          reserveAChange: formatUnits(reservesAfter[0] - reservesBefore[0], 18),
          reserveBChange: formatUnits(reservesAfter[1] - reservesBefore[1], 18),
        });
      }
    } catch (err) {
      console.error("Add liquidity failed:", err);
    }
  };

  return (
    <Card className="max-w-md mx-auto shadow-2xl border-2 border-border/50">
      <CardHeader>
        <CardTitle className="text-center flex items-center justify-center gap-2">
          <ArrowDownUp className="h-5 w-5 text-primary" />
          Swap Tokens
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* From Token Section */}
        <div className="space-y-2">
          <div className="flex justify-between items-center text-sm">
            <span className="text-muted-foreground">You sell</span>
            <button
              onClick={() =>
                fromTokenBalance && setFromAmount(fromTokenBalance.formatted)
              }
              className="text-xs text-primary hover:text-primary/80 transition-colors"
              disabled={isProcessing}
            >
              Balance: {fromTokenBalance ? parseFloat(fromTokenBalance.formatted).toFixed(4) : "0.00"}
            </button>
          </div>
          <div className="relative">
            <Input
              type="text"
              value={fromAmount}
              onChange={handleFromAmountChange}
              placeholder="0.0"
              className="pr-24 text-lg h-14 bg-secondary/50"
              disabled={isProcessing}
            />
            <div className="absolute right-3 top-1/2 -translate-y-1/2">
              <TokenSelector
                value={fromToken}
                onChange={(newFromToken) => {
                  setFromToken(newFromToken);
                  setToToken(
                    newFromToken === TOKEN_A_SYMBOL
                      ? TOKEN_B_SYMBOL
                      : TOKEN_A_SYMBOL
                  );
                }}
                disabled={isProcessing}
              />
            </div>
          </div>
        </div>

        {/* Swap Direction Button */}
        <div className="flex justify-center -my-2">
          <Button
            onClick={handleSwapTokens}
            variant="outline"
            size="icon"
            className="rounded-full h-10 w-10 border-4 border-background shadow-lg hover:rotate-180 transition-all duration-300"
            disabled={isProcessing}
          >
            <ArrowDownUp className="h-4 w-4" />
          </Button>
        </div>

        {/* To Token Section */}
        <div className="space-y-2">
          <div className="flex justify-between items-center text-sm">
            <span className="text-muted-foreground">You receive</span>
          </div>
          <div className="relative">
            <Input
              type="text"
              value={toAmount}
              readOnly
              placeholder="0.0"
              className="pr-24 text-lg h-14 bg-secondary/50"
            />
            <Badge className="absolute right-3 top-1/2 -translate-y-1/2 px-3 py-1.5">
              {toToken}
            </Badge>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="pt-2">
          {needsApproval() ? (
            <Button
              onClick={handleApprove}
              disabled={
                isProcessing ||
                !isConnected ||
                !fromAmount ||
                parseFloat(fromAmount) <= 0
              }
              className="w-full h-12 text-base font-semibold"
              variant="secondary"
            >
              {isApproving || isConfirmingApprove ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Approving...
                </>
              ) : (
                `Approve ${fromToken}`
              )}
            </Button>
          ) : (
            <Button
              onClick={handleSwap}
              disabled={
                isProcessing ||
                !isConnected ||
                !fromAmount ||
                parseFloat(fromAmount) <= 0
              }
              className="w-full h-12 text-base font-semibold"
            >
              {isSwapping || isConfirmingSwap ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Swapping...
                </>
              ) : !isConnected ? (
                "Connect Wallet"
              ) : (
                "Swap"
              )}
            </Button>
          )}
        </div>

        {/* Processing Status */}
        {isProcessing && (
          <div className="flex items-center justify-center gap-2 p-3 bg-yellow-500/10 border border-yellow-500/20 rounded-lg">
            <Loader2 className="h-4 w-4 animate-spin text-yellow-500" />
            <span className="text-sm text-yellow-600 dark:text-yellow-400">
              Processing transaction...
            </span>
          </div>
        )}

        {/* Error Display */}
        {(approveError || swapError) && (
          <div className="p-3 bg-destructive/10 border border-destructive/20 rounded-lg">
            <p className="text-sm text-destructive text-center break-words">
              {(approveError || swapError)?.shortMessage || "An error occurred."}
            </p>
          </div>
        )}

        {/* Success Messages */}
        {isSuccessApprove && (
          <div className="p-3 bg-primary/10 border border-primary/20 rounded-lg">
            <p className="text-sm text-primary text-center">
              Approval successful! You can now swap.
            </p>
          </div>
        )}
        {isSuccessSwap && (
          <div className="p-3 bg-primary/10 border border-primary/20 rounded-lg">
            <p className="text-sm text-primary text-center">
              Swap successful!
            </p>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
