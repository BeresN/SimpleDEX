"use client";

import { useState } from "react";
import {
  useAccount,
  useBalance,
  useReadContract,
  useWriteContract,
  useWaitForTransactionReceipt,
} from "wagmi";
import { parseUnits, parseEther, erc20Abi, formatUnits } from "viem";
import { Droplets, Plus, Minus, Loader2, TrendingUp, Wallet } from "lucide-react";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Badge } from "@/components/ui/badge";
import "tailwindcss";
import liquidityPoolAbi from "../../../abis/liquidityPoolAbi.json";
import factoryAbi from "../../../abis/factoryAbi.json";

import LoadingSpinner from "../utils/LoadingSpinner.js";

const LIQUIDITY_POOL_ADDRESS = "0xBAD4F032cC2Fd09b0C71B2D3336dD4A6beF724a7";
const FACTORY_ADDRESS = "0x39D59a27a78E15ed245E3706c5eCFEc0131A6B45";

const TOKEN_A_ADDRESS = "0x558f6e1BFfD83AD9F016865bF98D6763566d49c6";
const TOKEN_B_ADDRESS = "0x4DF4493209006683e678983E1Ec097680AB45e13";
const TOKEN_A_SYMBOL = "mETH";
const TOKEN_B_SYMBOL = "mSEI";
const LP_TOKEN_SYMBOL = "LPTK";
const MaxUint256 = BigInt(
  "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
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
  <div className="space-y-2">
    <div className="flex justify-between items-center text-sm">
      <span className="text-muted-foreground">{label}</span>
      {balance && (
        <div className="flex items-center gap-2">
          <span className="text-xs text-muted-foreground">
            Balance: {parseFloat(balance.formatted).toFixed(4)}
          </span>
          {onMaxClick && (
            <Button
              onClick={onMaxClick}
              variant="ghost"
              size="sm"
              className="h-6 px-2 text-xs text-primary hover:text-primary/80"
              disabled={disabled || !parseFloat(balance.formatted) > 0}
            >
              MAX
            </Button>
          )}
        </div>
      )}
    </div>
    <div className="relative">
      <Input
        type="text"
        inputMode="decimal"
        value={value}
        onChange={onChange}
        placeholder={placeholder || "0.0"}
        className="pr-20 text-lg h-14 bg-secondary/50"
        disabled={disabled}
      />
      <Badge className="absolute right-3 top-1/2 -translate-y-1/2 px-3 py-1.5">
        {symbol}
      </Badge>
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

  const { data: allPairsLength, refetch: refetchAllPairsLength } =
    useReadContract({
      address: FACTORY_ADDRESS,
      functionName: "allPairsLength",
      abi: factoryAbi,
      enabled: isConnected,
    });
  const { data: contractOwner } = useReadContract({
    address: FACTORY_ADDRESS,
    abi: factoryAbi,
    functionName: "owner",
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
  const {
    data: createPairData,
    writeContractAsync: createPairTx,
    isPending: isCreatingPair,
    error: createPairError,
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

  const isPairCreated = async () => {
    if (!isConnected) return;

    try {
      const pair = await refetchAllPairsLength();
      console.log("Checking if pair is already created:");
      if (pair.length > 0) {
        console.log("Pair already created");
      }
      return pair.length > 0;
    } catch (error) {
      console.error("Error checking reserves:", error);
    }
  };

  const createPair = async () => {
    if (!isConnected) return;

    try {
      console.log(
        "Creating new pair for tokens:",
        TOKEN_A_ADDRESS,
        TOKEN_B_ADDRESS,
      );

      const tx = await createPairTx({
        address: FACTORY_ADDRESS,
        abi: factoryAbi,
        functionName: "CreateNewPair",
        args: [TOKEN_A_ADDRESS, TOKEN_B_ADDRESS],
      });

      console.log("Pair created:", tx);
      return tx;
    } catch (err) {
      console.error("Create pair failed:", err);
      alert(`Failed to create pair: ${err.message}`);
    }
  };

  const handleAddLiquidityWithApprove = async () => {
    if (!isConnected || !amountA || !amountB || !balanceA || !balanceB) return;

    try {
      const pairExists = await isPairCreated();

      if (!pairExists) {
        console.log("Pair doesn't exist, creating...");
        const pairCreationReceipt = await createPair();
        if (!pairCreationReceipt) {
          console.log("Pair creation failed");
          return;
        }
        console.log("Pair created successfully, proceeding to add liquidity");
      } else {
        console.log("Pair already exists, proceeding to add liquidity");
      }

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

      console.log("Adding liquidity...");
      const tx = await addLiquidityTx({
        address: LIQUIDITY_POOL_ADDRESS,
        abi: liquidityPoolAbi,
        functionName: "addLiquidity",
        args: [amountAWei, amountBWei],
      });
      console.log("Add liquidity transaction sent:", tx);
      // Now check reserves AFTER the transaction is confirmed

      return tx;
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
    <div className="space-y-4">
      <InputField
        label={`${TOKEN_A_SYMBOL} Amount`}
        value={amountA}
        onChange={handleAmountChange(setAmountA)}
        balance={balanceA}
        symbol={TOKEN_A_SYMBOL}
        onMaxClick={() => balanceA && setAmountA(balanceA.formatted)}
        disabled={isProcessing || !isConnected}
      />
      <InputField
        label={`${TOKEN_B_SYMBOL} Amount`}
        value={amountB}
        onChange={handleAmountChange(setAmountB)}
        balance={balanceB}
        symbol={TOKEN_B_SYMBOL}
        onMaxClick={() => balanceB && setAmountB(balanceB.formatted)}
        disabled={isProcessing || !isConnected}
      />

      <div className="pt-2">
        <Button
          onClick={handleAddLiquidityWithApprove}
          disabled={
            isProcessing ||
            !isConnected ||
            !amountA ||
            !amountB ||
            parseFloat(amountA) <= 0 ||
            parseFloat(amountB) <= 0
          }
          className="w-full h-12 text-base font-semibold"
        >
          {isAddingLiquidity ? (
            <>
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              Adding Liquidity...
            </>
          ) : (
            <>
              <Plus className="mr-2 h-4 w-4" />
              Add Liquidity
            </>
          )}
        </Button>
      </div>
    </div>
  );

  const renderRemoveLiquidity = () => (
    <div className="space-y-4">
      <InputField
        label="LP Token Amount"
        value={lpAmount}
        onChange={handleAmountChange(setLpAmount)}
        balance={balanceLP}
        symbol={LP_TOKEN_SYMBOL}
        onMaxClick={() => {
          if (balanceLP) {
            setLpAmount(balanceLP.formatted);
          }
        }}
        disabled={isProcessing || !isConnected}
      />

      <div className="pt-2">
        <Button
          onClick={handleRemoveLiquidity}
          disabled={
            isProcessing ||
            !isConnected ||
            !lpAmount ||
            parseFloat(lpAmount) <= 0
          }
          variant="destructive"
          className="w-full h-12 text-base font-semibold"
        >
          {isRemovingLiquidity ? (
            <>
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              Removing Liquidity...
            </>
          ) : (
            <>
              <Minus className="mr-2 h-4 w-4" />
              Remove Liquidity
            </>
          )}
        </Button>
      </div>
    </div>
  );

  return (
    <Card className="max-w-md mx-auto shadow-2xl border-2 border-border/50">
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="flex items-center gap-2">
            <Droplets className="h-5 w-5 text-primary" />
            Liquidity Pool
          </CardTitle>
          <ConnectButton
            showBalance={false}
            chainStatus="icon"
            accountStatus="address"
          />
        </div>
      </CardHeader>
      <CardContent>
        {!isConnected ? (
          <div className="text-center py-12 space-y-3">
            <Wallet className="h-12 w-12 mx-auto text-muted-foreground/50" />
            <p className="text-muted-foreground">
              Please connect your wallet to manage liquidity.
            </p>
          </div>
        ) : (
          <Tabs value={viewMode} onValueChange={setViewMode} className="w-full">
            <TabsList className="grid w-full grid-cols-2 mb-6">
              <TabsTrigger value="add" disabled={isProcessing}>
                <Plus className="h-4 w-4 mr-1" />
                Add
              </TabsTrigger>
              <TabsTrigger value="remove" disabled={isProcessing}>
                <Minus className="h-4 w-4 mr-1" />
                Remove
              </TabsTrigger>
            </TabsList>
            <TabsContent value="add" className="space-y-4">
              {renderAddLiquidity()}
            </TabsContent>
            <TabsContent value="remove" className="space-y-4">
              {renderRemoveLiquidity()}
            </TabsContent>
          </Tabs>
        )}

        {/* Processing Status */}
        {isProcessing && (
          <div className="mt-4 flex items-center justify-center gap-2 p-3 bg-yellow-500/10 border border-yellow-500/20 rounded-lg">
            <Loader2 className="h-4 w-4 animate-spin text-yellow-500" />
            <span className="text-sm text-yellow-600 dark:text-yellow-400">
              Processing transaction...
            </span>
          </div>
        )}

        {/* Transaction Feedback */}
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

        {/* Error Display */}
        {(approveAError || approveBError || addLiqError || remLiqError) && (
          <div className="mt-4 p-3 bg-destructive/10 border border-destructive/20 rounded-lg">
            <p className="text-sm text-destructive text-center break-words">
              {(approveAError || approveBError || addLiqError || remLiqError)
                ?.shortMessage || "An error occurred."}
            </p>
          </div>
        )}
      </CardContent>
    </Card>
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
      className={`mt-4 p-3 border rounded-lg text-center text-sm ${
        isSuccess
          ? "bg-primary/10 border-primary/20"
          : isLoading || pending
            ? "bg-yellow-500/10 border-yellow-500/20"
            : "bg-muted border-muted-foreground/20"
      }`}
    >
      <div className="flex items-center justify-center gap-2 mb-1">
        {isLoading && <Loader2 className="h-4 w-4 animate-spin text-yellow-500" />}
        <span className={isSuccess ? "text-primary" : isLoading || pending ? "text-yellow-600 dark:text-yellow-400" : "text-muted-foreground"}>
          {isSuccess
            ? successMessage
            : isLoading || pending
              ? "Transaction Pending..."
              : "Transaction Initiated"}
        </span>
      </div>
      <a
        href={`https://sepolia.etherscan.io/tx/${hash}`}
        target="_blank"
        rel="noopener noreferrer"
        className="text-xs text-primary hover:text-primary/80 underline font-mono break-all"
      >
        View on Etherscan
      </a>
    </div>
  );
};
