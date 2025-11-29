"use client";
import { useState } from "react";
import {
  useAccount,
  useBalance,
  useWriteContract,
  useWaitForTransactionReceipt,
} from "wagmi";
import { isAddress, erc20Abi, parseEther } from "viem";
import { Send, Loader2, CheckCircle2, AlertCircle } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import TokenSelector from "@/components/TokenSelector";
import "tailwindcss";

const TOKEN_A_ADDRESS = "0x558f6e1BFfD83AD9F016865bF98D6763566d49c6";
const TOKEN_B_ADDRESS = "0x4DF4493209006683e678983E1Ec097680AB45e13";
const TOKEN_A_SYMBOL = "mETH";
const TOKEN_B_SYMBOL = "mSEI";

export default function SendInterface() {
  const [fromToken, setTokenToSend] = useState(TOKEN_A_SYMBOL);
  const [sendAmount, setSendAmount] = useState("");
  const [isRecipientValid, setIsRecipientValid] = useState(false);
  const [recipientTouched, setRecipientTouched] = useState(false);
  const [recipientAddress, setRecipientAddress] = useState("");
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

  const tokenBalance = fromToken === TOKEN_A_SYMBOL ? balanceA : balanceB;
  const tokenAddress =
    fromToken === TOKEN_A_SYMBOL ? TOKEN_A_ADDRESS : TOKEN_B_ADDRESS;

  const handleTokenChange = (newTokenSymbol) => {
    setTokenToSend(newTokenSymbol);
    setSendAmount("");
  };

  const handleAmountChange = (e) => {
    const value = e.target.value;
    if (/^\d*\.?\d*$/.test(value)) {
      setSendAmount(value);
    }
  };

  const handleRecipientChange = (e) => {
    const value = e.target.value;
    setRecipientAddress(value);
    setRecipientTouched(true);

    if (value && isAddress(value)) {
      setIsRecipientValid(true);
    } else {
      setIsRecipientValid(false);
    }
  };

  const {
    data: sendData,
    writeContractAsync,
    isPending,
    error: sendError,
  } = useWriteContract();

  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash: sendData?.hash,
  });

  const isProcessing = isPending || isConfirming;

  const handleSend = async () => {
    if (!isConnected || !sendAmount || !isRecipientValid) return;

    try {
      await writeContractAsync({
        address: tokenAddress,
        abi: erc20Abi,
        functionName: "transfer",
        args: [recipientAddress, parseEther(sendAmount)],
      });
    } catch (err) {
      console.error("Transfer failed:", err);
    }
  };

  return (
    <Card className="max-w-md mx-auto shadow-2xl border-2 border-border/50">
      <CardHeader>
        <CardTitle className="text-center flex items-center justify-center gap-2">
          <Send className="h-5 w-5 text-primary" />
          Send Tokens
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Token Amount Section */}
        <div className="space-y-2">
          <div className="flex justify-between items-center text-sm">
            <span className="text-muted-foreground">You send</span>
            <button
              onClick={() =>
                tokenBalance && setSendAmount(tokenBalance.formatted)
              }
              className="text-xs text-primary hover:text-primary/80 transition-colors"
              disabled={isProcessing}
            >
              Balance:{" "}
              {tokenBalance
                ? parseFloat(tokenBalance.formatted).toFixed(4)
                : "0.00"}
            </button>
          </div>
          <div className="relative">
            <Input
              type="text"
              value={sendAmount}
              onChange={handleAmountChange}
              placeholder="0.0"
              className="pr-24 text-lg h-14 bg-secondary/50"
              disabled={isProcessing}
            />
            <div className="absolute right-3 top-1/2 -translate-y-1/2">
              <TokenSelector
                value={fromToken}
                onChange={handleTokenChange}
                disabled={isProcessing}
              />
            </div>
          </div>
        </div>

        {/* Recipient Address Section */}
        <div className="space-y-2">
          <div className="flex justify-between items-center text-sm">
            <span className="text-muted-foreground">To address</span>
            {recipientTouched && isRecipientValid && (
              <Badge variant="secondary" className="text-xs gap-1">
                <CheckCircle2 className="h-3 w-3" />
                Valid
              </Badge>
            )}
          </div>
          <div className="relative">
            <Input
              type="text"
              value={recipientAddress}
              onChange={handleRecipientChange}
              placeholder="0x..."
              className={`text-sm h-14 font-mono ${recipientTouched && !isRecipientValid && recipientAddress
                ? "border-destructive focus-visible:ring-destructive"
                : ""
                }`}
              disabled={isProcessing}
            />
            {recipientTouched && !isRecipientValid && recipientAddress && (
              <div className="absolute right-3 top-1/2 -translate-y-1/2">
                <AlertCircle className="h-4 w-4 text-destructive" />
              </div>
            )}
          </div>
          {recipientTouched && !isRecipientValid && recipientAddress && (
            <p className="text-xs text-destructive flex items-center gap-1">
              <AlertCircle className="h-3 w-3" />
              Please enter a valid Ethereum address
            </p>
          )}
        </div>

        {/* Send Button */}
        <div className="pt-2">
          <Button
            onClick={handleSend}
            disabled={
              isProcessing ||
              !isConnected ||
              !sendAmount ||
              !isRecipientValid ||
              parseFloat(sendAmount) <= 0
            }
            className="w-full h-12 text-base font-semibold"
          >
            {isProcessing ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                {isPending ? "Confirming..." : "Sending..."}
              </>
            ) : !isConnected ? (
              "Connect Wallet"
            ) : !sendAmount ? (
              "Enter amount"
            ) : !recipientAddress ? (
              "Enter recipient"
            ) : !isRecipientValid ? (
              "Invalid address"
            ) : (
              "Send"
            )}
          </Button>
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
        {sendError && (
          <div className="p-3 bg-destructive/10 border border-destructive/20 rounded-lg">
            <p className="text-sm text-destructive text-center break-words">
              {sendError?.shortMessage || "Transfer failed. Please try again."}
            </p>
          </div>
        )}

        {/* Success Message */}
        {isSuccess && (
          <div className="p-3 bg-primary/10 border border-primary/20 rounded-lg">
            <p className="text-sm text-primary text-center flex items-center justify-center gap-2">
              <CheckCircle2 className="h-4 w-4" />
              Transfer successful!
            </p>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
