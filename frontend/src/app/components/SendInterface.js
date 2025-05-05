"use client";
import { useState } from "react";
import {
  useAccount,
  useBalance,
  useReadContract,
  useWriteContract,
} from "wagmi";
import { isAddress, erc20Abi, parseEther } from "viem";
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

  const { writeContractAsync, isPending, isSuccess, isError, error } =
    useWriteContract();

  const handleSend = () => {
    console.log("token a balance: ", balanceA);
    console.log("token b balance: ", balanceB);

    try {
      writeContractAsync({
        address: tokenAddress,
        abi: erc20Abi,
        functionName: "transfer",
        args: [recipientAddress, parseEther(sendAmount)],
      });
    } catch (err) {
      console.log("transfer failed: ", err);
    }
  };

  return (
    <div className="bg-gray-800 rounded-xl p-4 max-w-md mx-auto mt-8 text-white justify-center">
      <div className="bg-gray-800 text-white p-4 max-w-md mx-auto rounded-xl">
        {isConnected && (
          <span>Balance: {tokenBalance ? tokenBalance.formatted : "0.00"}</span>
        )}
        <div className="text-center text-gray-400 mb-2 text-sm">
          You are sending
        </div>
        <div className="bg-gray-900 p-3 rounded-xl flex justify-between mb-4 self-center">
          <input
            type="text"
            value={sendAmount}
            onChange={handleAmountChange}
            placeholder="0.00"
            className="w-full bg-gray-900 rounded p-2 text-center outline-none"
          />
          <select
            value={fromToken}
            onChange={(e) => handleTokenChange(e.target.value)}
            className="bg-gray-700 rounded-xl p-2"
          >
            <option value="mETH">mETH</option>
            <option value="mSEI">mSEI</option>
          </select>
        </div>

        {/* To section */}
        <div className="mb-6">
          <div className="text-center text-gray-400 mb-4 text-sm">To</div>
          <input
            type="text"
            value={recipientAddress}
            onChange={handleRecipientChange}
            placeholder="provide wallet address"
            className={`w-full bg-gray-900 border ${
              recipientTouched && !isRecipientValid && recipientAddress // Show red border only if touched, not empty, and invalid
                ? "border-red-500 focus:border-red-500 focus:ring-red-500" // Invalid style
                : "border-gray-900 focus:border-emerald-500 focus:ring-emerald-500" // Default/valid style
            } rounded-lg p-2 text-center text-base font-mono transition-colors duration-150 outline-none focus:ring-1`} // Added focus styles, mono font
          />
          {recipientTouched && !isRecipientValid && recipientAddress && (
            <p className="text-red-500 text-xs text-center mt-1">
              Please enter a valid Ethereum address.
            </p>
          )}
        </div>
      </div>
      {isSuccess && (
        <div className="bg-green-900/50 border border-green-500 text-green-200 p-2 rounded-lg mb-4 text-sm text-center">
          Transfer successful!
        </div>
      )}
      {isError && (
        <div className="border-red-500 focus:border-red-500 focus:ring-red-500">
          Transfer Failed!
        </div>
      )}

      <button
        onClick={handleSend}
        className={`w-full py-3 rounded-xl font-bold ${
          // Check isRecipientValid here
          isConnected && sendAmount && isRecipientValid
            ? "bg-gradient-to-r from-emerald-600 to-green-500 hover:from-emerald-700 hover:to-green-600" // Added hover
            : "bg-gray-900 text-gray-500 cursor-not-allowed" // Updated disabled style
        } transition duration-200 ease-in-out`}
        // Update disabled check
        disabled={!isConnected || !sendAmount || !isRecipientValid || isPending}
      >
        {!isConnected
          ? "Connect Wallet"
          : !sendAmount
          ? "Enter an amount"
          : !recipientAddress
          ? "Enter recipient"
          : !isRecipientValid
          ? "Invalid Address"
          : "Send"}
        {isPending ? "Pending transaction" : isRecipientValid}
      </button>
    </div>
  );
}
