"use client";

import { useState, useEffect } from "react";
import {
  useAccount,
  useBalance,
  useReadContract,
  useWriteContract,
  useWaitForTransactionReceipt,
} from "wagmi";
import { parseUnits, formatUnits, MaxUint256 } from "viem";
import { erc20Abi } from "viem";
import "tailwindcss";
import swapAbi from "../../../abis/swapAbi.json";

const TOKEN_A_ADDRESS = "0x558f6e1BFfD83AD9F016865bF98D6763566d49c6";
const TOKEN_B_ADDRESS = "0x4DF4493209006683e678983E1Ec097680AB45e13";
const SWAP_CONTRACT_ADDRESS = "0xBAD4F032cC2Fd09b0C71B2D3336dD4A6beF724a7";
const TOKEN_A_SYMBOL = "mETH";
const TOKEN_B_SYMBOL = "mSEI";

export default function SwapInterface() {
  const [fromToken, setFromToken] = useState(TOKEN_A_SYMBOL);
  const [toToken, setToToken] = useState(TOKEN_B_SYMBOL);
  const [fromAmount, setFromAmount] = useState("");
  const [toAmount, setToAmount] = useState("");

  const { address, isConnected } = useAccount();

  // Balance hooks
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

  const fromTokenAddress =
    fromToken === TOKEN_A_SYMBOL ? TOKEN_A_ADDRESS : TOKEN_B_ADDRESS;
  const fromTokenBalance = fromToken === TOKEN_A_SYMBOL ? balanceA : balanceB;

  // Read allowance for the token being swapped
  const { data: allowance, refetch: refetchAllowance } = useReadContract({
    address: fromTokenAddress,
    abi: erc20Abi,
    functionName: "allowance",
    args: [address, SWAP_CONTRACT_ADDRESS],
    enabled: isConnected && !!address,
  });

  // Write contract hooks
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

  // Transaction receipt monitoring
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

  // Wait for approval transaction to be confirmed before proceeding
  const handleApprove = async () => {
    if (!isConnected || !fromAmount) return;
    try {
      const tx = await approveTx({
        address: fromTokenAddress,
        abi: erc20Abi,
        functionName: "approve",
        args: [SWAP_CONTRACT_ADDRESS, MaxUint256],
      });

      // Wait for confirmation
      const receipt = await waitForTransaction({ hash: tx.hash });
      console.log("Approval confirmed:", receipt);

      // Refetch allowance after confirmation
      await refetchAllowance();
    } catch (err) {
      console.error("Failed to approve:", err);
    }
  };

  // Add this to your swap function to get more detailed error information
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

      // Add gas limit and potentially other parameters
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
      // Mock price calculation - in a real app this would use actual exchange rates
      setToAmount(value * (fromToken === TOKEN_A_SYMBOL ? 1 : 1 / 2));
    }
  };

  return (
    <div className="bg-gray-800 rounded-xl p-4 max-w-md mx-auto mt-8 text-white justify-center">
      <div className="mb-4">
        <div className="mb-2 flex justify-between">
          <span>Sell</span>
          <span>
            Balance: {fromTokenBalance ? fromTokenBalance.formatted : "0.00"}
            <button
              onClick={() =>
                fromTokenBalance && setFromAmount(fromTokenBalance.formatted)
              }
            ></button>
          </span>
        </div>
        <div className="bg-gray-900 p-3 rounded-xl flex justify-between self-center">
          <input
            type="text"
            value={fromAmount}
            onChange={handleFromAmountChange}
            placeholder="0.0"
            className="bg-transparent outline-none w-2/3"
            disabled={isProcessing}
          />
          <select
            value={fromToken}
            onChange={(e) => {
              const newFromToken = e.target.value;
              setFromToken(newFromToken);
              setToToken(
                newFromToken === TOKEN_A_SYMBOL
                  ? TOKEN_B_SYMBOL
                  : TOKEN_A_SYMBOL
              );
            }}
            className="bg-gray-700 rounded-xl p-2"
            disabled={isProcessing}
          >
            <option value={TOKEN_A_SYMBOL}>{TOKEN_A_SYMBOL}</option>
            <option value={TOKEN_B_SYMBOL}>{TOKEN_B_SYMBOL}</option>
          </select>
        </div>
      </div>

      <div className="flex justify-center my-2">
        <button
          onClick={handleSwapTokens}
          className="bg-gray-700 p-1 rounded-full hover:bg-gray-600"
          disabled={isProcessing}
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            className="h-6 w-6"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M7 16V4m0 0L3 8m4-4l4 4m6 0v12m0 0l4-4m-4 4l-4-4"
            />
          </svg>
        </button>
      </div>

      <div className="mb-4">
        <div className="mb-2">
          <span>Buy</span>
        </div>
        <div className="bg-gray-900 p-3 rounded-xl flex justify-between">
          <input
            type="text"
            value={toAmount}
            readOnly
            placeholder="0.0"
            className="bg-transparent outline-none w-2/3"
          />
          <div className="bg-gray-700 rounded-xl p-2">{toToken}</div>
        </div>
      </div>

      <div className="mt-4">
        {needsApproval() ? (
          <button
            onClick={handleApprove}
            disabled={
              isProcessing ||
              !isConnected ||
              !fromAmount ||
              parseFloat(fromAmount) <= 0
            }
            className="w-full py-3 rounded-xl font-bold bg-blue-600 hover:bg-blue-700 text-white transition disabled:bg-gray-700 disabled:text-gray-500 disabled:cursor-not-allowed flex justify-center items-center"
          ></button>
        ) : (
          <button
            onClick={handleSwap}
            disabled={
              isProcessing ||
              !isConnected ||
              !fromAmount ||
              parseFloat(fromAmount) <= 0
            }
            className="w-full py-3 rounded-xl font-bold bg-gradient-to-r from-emerald-600 to-green-500 hover:from-emerald-700 hover:to-green-600 text-white transition disabled:bg-gray-700 disabled:text-gray-500 disabled:cursor-not-allowed flex justify-center items-center"
          >
            {isSwapping || isConfirmingSwap ? "Pending" : "Swap"}
          </button>
        )}
      </div>

      {isProcessing && (
        <div className="mt-4 text-center text-sm text-yellow-400">
          Processing Transaction... Check Wallet
        </div>
      )}

      {(approveError || swapError) && (
        <div className="mt-4 p-3 bg-red-900/50 border border-red-700 rounded-lg text-center text-red-300 text-xs break-words">
          Error:{" "}
          {(approveError || swapError)?.shortMessage || "An error occurred."}
        </div>
      )}
    </div>
  );
}
