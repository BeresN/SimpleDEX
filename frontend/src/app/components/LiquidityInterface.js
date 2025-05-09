"use client";

import { useState } from "react";
import {
  useAccount,
  useBalance,
  useReadContract,
  useWriteContract,
  useWaitForTransactionReceipt,
} from "wagmi";
import { parseUnits, parseEther, erc20Abi } from "viem";

import { ConnectButton } from "@rainbow-me/rainbowkit";
import "tailwindcss";
import liquidityPoolAbi from "../../../abis/liquidityPoolAbi.json";
import LoadingSpinner from "../utils/LoadingSpinner.js";

const LIQUIDITY_POOL_ADDRESS = "0xBAD4F032cC2Fd09b0C71B2D3336dD4A6beF724a7";
const TOKEN_A_ADDRESS = "0x558f6e1BFfD83AD9F016865bF98D6763566d49c6";
const TOKEN_B_ADDRESS = "0x4DF4493209006683e678983E1Ec097680AB45e13";
const TOKEN_A_SYMBOL = "mETH";
const TOKEN_B_SYMBOL = "mSEI";
const LP_TOKEN_SYMBOL = "LPTK";
const MaxUint256 = BigInt(
  "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
);
const InputField = ({
  label,
  value,
  onChange,
  placeholder,
  balance,
  symbol,
  onMaxClick,
  disabled,
}) => (
  <div className="bg-gray-900 p-4 rounded-xl mb-2">
    <div className="flex justify-between items-center mb-2 text-xs text-gray-400">
      <span>{label}</span>
      {balance && (
        <div className="flex items-center">
          <span>Balance: {balance.formatted}</span>
          {onMaxClick && (
            <button
              onClick={onMaxClick}
              className="ml-1.5 text-emerald-500 hover:text-emerald-400 text-xs font-bold disabled:text-gray-600 disabled:cursor-not-allowed"
              disabled={disabled || !parseFloat(balance.formatted) > 0}
            >
              MAX
            </button>
          )}
        </div>
      )}
    </div>
    <div className="flex items-center">
      <input
        type="text"
        inputMode="decimal"
        value={value}
        onChange={onChange}
        placeholder={placeholder || "0"}
        className="w-full bg-transparent text-2xl outline-none placeholder-gray-500 text-gray-100 disabled:opacity-70"
        disabled={disabled}
      />
      <span className="text-xl font-medium text-gray-300 ml-2">{symbol}</span>
    </div>
  </div>
);

export default function LiquidityInterface() {
  const [viewMode, setViewMode] = useState("add");
  const [amountA, setAmountA] = useState("");
  const [amountB, setAmountB] = useState("");
  const [lpAmount, setLpAmount] = useState("");
  const { address, isConnected } = useAccount();

  // --- Wagmi Hooks ---
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
    token: LIQUIDITY_POOL_ADDRESS,
    watch: true,
  });

  // Read Allowances
  const { data: allowanceA, refetch: refetchAllowanceA } = useReadContract({
    address: TOKEN_A_ADDRESS,
    functionName: "allowance",
    abi: erc20Abi,
    args: [address, LIQUIDITY_POOL_ADDRESS],
    enabled: isConnected,
  });
  const { data: allowanceB, refetch: refetchAllowanceB } = useReadContract({
    address: TOKEN_B_ADDRESS,
    functionName: "allowance",
    abi: erc20Abi,
    args: [address, LIQUIDITY_POOL_ADDRESS],
    enabled: isConnected,
  });

  // Contract Write Hooks
  const {
    data: approveAData,
    writeContractAsync: approveATx,
    isPending: isApprovingA,
    error: approveAError,
  } = useWriteContract();
  const {
    data: approveBData,
    writeContractAsync: approveBTx,
    isPending: isApprovingB,
    error: approveBError,
  } = useWriteContract();
  const {
    data: addLiqData,
    writeContractAsync: addLiquidityTx,
    isPending: isAddingLiquidity,
    error: addLiqError,
  } = useWriteContract();
  const {
    data: remLiqData,
    writeContractAsync: removeLiquidityTx,
    isPending: isRemovingLiquidity,
    error: remLiqError,
  } = useWriteContract();

  // Monitor approval tx receipt
  const { isLoading: isConfirmingApproveA, isSuccess: isSuccessApproveA } =
    useWaitForTransactionReceipt({ hash: approveAData?.hash });
  const { isLoading: isConfirmingApproveB, isSuccess: isSuccessApproveB } =
    useWaitForTransactionReceipt({ hash: approveBData?.hash });

  const isApprovalPending =
    isApprovingA ||
    isConfirmingApproveA ||
    isApprovingB ||
    isConfirmingApproveB;
  const isProcessing =
    isApprovalPending || isAddingLiquidity || isRemovingLiquidity;

  const handleAmountChange = (setter) => (e) => {
    const value = e.target.value;
    if (/^\d*\.?\d*$/.test(value)) {
      setter(value);
    }
  };

  const handleAddLiquidityWithApprove = async () => {
    if (!isConnected || !amountA || !amountB || !balanceA || !balanceB) return;

    try {
      const amountAWei = parseUnits(amountA, balanceA.decimals);
      const amountBWei = parseUnits(amountB, balanceB.decimals);

      const needApprovalA = allowanceA < amountAWei;
      const needApprovalB = allowanceB < amountBWei;

      if (needApprovalA) {
        const tx = await approveATx({
          address: TOKEN_A_ADDRESS,
          abi: erc20Abi,
          functionName: "approve",
          args: [LIQUIDITY_POOL_ADDRESS, MaxUint256],
        });
        console.log(`Waiting for ${TOKEN_A_SYMBOL} approval...`);
        const receiptA = await waitForTransaction({ hash: tx.hash });
        console.log(`${TOKEN_A_SYMBOL} approved!`);
      }

      if (needApprovalB) {
        const tx = await approveBTx({
          address: TOKEN_B_ADDRESS,
          abi: erc20Abi,
          functionName: "approve",
          args: [LIQUIDITY_POOL_ADDRESS, MaxUint256],
        });
        console.log(`Waiting for ${TOKEN_B_SYMBOL} approval...`);
        const receiptA = await waitForTransaction({ hash: tx.hash });
        console.log(`${TOKEN_B_SYMBOL} approved!`);
      }
      if (!needApprovalA && !needApprovalB) {
        console.log("Adding liquidity...");
        const tx = await addLiquidityTx({
          address: LIQUIDITY_POOL_ADDRESS,
          abi: liquidityPoolAbi,
          functionName: "addLiquidity",
          args: [amountAWei, amountBWei],
        });
        console.log("Add liquidity transaction sent:", tx.hash);
        return tx;
      }
    } catch (err) {
      console.error("Add liquidity failed:", err);
      alert(`Failed to add liquidity: ${err.message}`);
    }
  };

  const handleRemoveLiquidity = async () => {
    if (!isConnected || !lpAmount || !balanceLP || parseFloat(lpAmount) <= 0)
      return;
    try {
      const lpAmountWei = parseEther(lpAmount, balanceLP.decimals);

      if (lpAmountWei > balanceLP.value) {
        alert("Insufficient LP token balance.");
        return;
      }

      await removeLiquidityTx({
        address: LIQUIDITY_POOL_ADDRESS,
        abi: liquidityPoolAbi,
        functionName: "removeLiquidity",
        args: [lpAmountWei],
      });
    } catch (err) {
      console.error("Remove liquidity failed:", err);
    }
  };

  // --- Render Logic ---
  const renderAddLiquidity = () => (
    <>
      <InputField
        label="Amount A"
        value={amountA}
        onChange={handleAmountChange(setAmountA)}
        balance={balanceA}
        symbol={TOKEN_A_SYMBOL}
        onMaxClick={() => balanceA && setAmountA(balanceA.formatted)}
        disabled={isProcessing || !isConnected}
      />
      <InputField
        label="Amount B"
        value={amountB}
        onChange={handleAmountChange(setAmountB)}
        balance={balanceB}
        symbol={TOKEN_B_SYMBOL}
        onMaxClick={() => balanceB && setAmountB(balanceB.formatted)}
        disabled={isProcessing || !isConnected}
      />

      <div className="mt-4 space-y-3">
        <button
          onClick={handleAddLiquidityWithApprove}
          disabled={
            isProcessing ||
            !isConnected ||
            !amountA ||
            !amountB ||
            parseFloat(amountA) <= 0 ||
            parseFloat(amountB) <= 0
          }
          className="w-full py-3 rounded-xl font-semibold text-lg bg-emerald-600 hover:bg-emerald-700 text-white transition duration-200 disabled:bg-gray-700 disabled:text-gray-500 disabled:cursor-not-allowed flex justify-center items-center"
        >
          {isAddingLiquidity ? <LoadingSpinner /> : "Add Liquidity"}
        </button>
      </div>
    </>
  );

  const renderRemoveLiquidity = () => (
    <>
      <InputField
        label="Amount LP Tokens"
        value={lpAmount}
        onChange={handleAmountChange(setLpAmount)}
        balance={balanceLP}
        symbol={LP_TOKEN_SYMBOL}
        onMaxClick={() => balanceLP && setLpAmount(balanceLP.formatted)}
        disabled={isProcessing || !isConnected}
      />

      <div className="mt-3">
        <button
          onClick={handleRemoveLiquidity}
          disabled={
            isProcessing ||
            !isConnected ||
            !lpAmount ||
            parseFloat(lpAmount) <= 0
          }
          className="w-full py-3 rounded-xl font-semibold text-lg bg-red-600 hover:bg-red-700 text-white transition duration-200 disabled:bg-gray-700 disabled:text-gray-500 disabled:cursor-not-allowed flex justify-center items-center"
        >
          {isRemovingLiquidity ? <LoadingSpinner /> : "Remove Liquidity"}
        </button>
      </div>
    </>
  );

  return (
    <div className="bg-gray-800 rounded-2xl p-4 sm:p-5 max-w-md mx-auto mt-8 text-white border border-gray-700 shadow-lg">
      <div className="flex justify-between items-center mb-5">
        <div className="flex flex-col space-y-2">
          <button
            onClick={() => setViewMode("add")}
            className={`px-4 py-2 rounded-lg text-sm font-medium ${
              viewMode === "add"
                ? "bg-emerald-600 text-white"
                : "bg-gray-700 text-gray-300 hover:bg-gray-600"
            }`}
            disabled={isProcessing}
          >
            Add Liquidity
          </button>
          <button
            onClick={() => setViewMode("remove")}
            className={`px-4 py-2 rounded-lg text-sm font-medium ${
              viewMode === "remove"
                ? "bg-red-600 text-white"
                : "bg-gray-700 text-gray-300 hover:bg-gray-600"
            }`}
            disabled={isProcessing}
          >
            Remove Liquidity
          </button>
        </div>

        <ConnectButton
          showBalance={false}
          chainStatus="icon"
          accountStatus="address"
        />
      </div>

      {!isConnected ? (
        <div className="text-center text-gray-400 py-8">
          Please connect your wallet.
        </div>
      ) : viewMode === "add" ? (
        renderAddLiquidity()
      ) : (
        renderRemoveLiquidity()
      )}

      {isProcessing && (
        <div className="mt-4 text-center text-sm text-yellow-400">
          Processing Transaction... Check Wallet
        </div>
      )}
      {addLiqData && (
        <TxFeedback hash={addLiqData.hash} successMessage="Liquidity Added!" />
      )}
      {remLiqData && (
        <TxFeedback
          hash={remLiqData.hash}
          successMessage="Liquidity Removed!"
        />
      )}
      {approveAData && isSuccessApproveA && (
        <TxFeedback
          hash={approveAData.hash}
          successMessage={`${TOKEN_A_SYMBOL} Approved!`}
          pending
        />
      )}
      {approveBData && isSuccessApproveB && (
        <TxFeedback
          hash={approveBData.hash}
          successMessage={`${TOKEN_B_SYMBOL} Approved!`}
          pending
        />
      )}

      {(approveAError || approveBError || addLiqError || remLiqError) && (
        <div className="mt-4 p-3 bg-red-900/50 border border-red-700 rounded-lg text-center text-red-300 text-xs break-words">
          Error:{" "}
          {(approveAError || approveBError || addLiqError || remLiqError)
            ?.shortMessage || "An error occurred."}
        </div>
      )}
    </div>
  );
}

// Helper component for Transaction Feedback
const TxFeedback = ({ hash, successMessage, pending = false }) => {
  const {
    data: receipt,
    isLoading,
    isSuccess,
  } = useWaitForTransactionReceipt({ hash });

  if (!hash) return null;

  return (
    <div
      className={`mt-4 p-2 border rounded-lg text-center text-xs sm:text-sm break-all ${
        isSuccess
          ? "bg-green-900/50 border-green-700/50 text-green-300"
          : isLoading || pending
          ? "bg-yellow-900/50 border-yellow-700/50 text-yellow-300"
          : "bg-gray-700 border-gray-600 text-gray-300" // Default or pending state
      }`}
    >
      {isSuccess
        ? successMessage
        : isLoading || pending
        ? "Transaction Pending..."
        : "Transaction Initiated"}{" "}
      <br />
      <a
        href={"https://sepolia.etherscan.io/tx/${hash}"}
        target="_blank"
        rel="noopener noreferrer"
        className="underline hover:text-white font-mono"
      >
        {hash.substring(0, 6)}...{hash.substring(hash.length - 4)}
      </a>
      {isLoading && (
        <span className="ml-2">
          <LoadingSpinner />
        </span>
      )}
    </div>
  );
};
