'use client';
import { useState } from 'react';
import { useAccount, useBalance, useReadContract, useWriteContract, } from 'wagmi';
import { isAddress, erc20Abi } from 'viem';
import "tailwindcss";

const TOKEN_ADDRESSES = {
    ETH: '0xfff9976782d46cc05630d1f6ebab18b2324d6b14',
  };

export default function SendInterface() {
    const [tokenToSend, setTokenToSend] = useState("sETH");
    const [sendAmount, setSendAmount] = useState("");
    const [isRecipientValid, setIsRecipientValid] = useState(false); // State for validity
    const [recipientTouched, setRecipientTouched] = useState(false); // Optional: track if user interacted
    const [recipientAddress, setRecipientAddress] = useState(""); // Assuming you have this state elsewhere
    const { address, isConnected } = useAccount();
    const { data: balance, isLoading: isLoadingBalance} = useBalance({
      address,
      token: tokenToSend === "sETH" ? undefined : TOKEN_ADDRESSES[ETH],
      watch: true, // Optional: refreshes balance on network changes
    });

  const handleTokenChange = (newTokenSymbol) => {
    setTokenToSend(newTokenSymbol);
    // Optional: Reset amount when token changes to avoid confusion
    setSendAmount("");
  };

  const handleAmountChange = (e) => {
    const value = e.target.value;
    // Basic validation: allow only numbers and one decimal point
    if (/^\d*\.?\d*$/.test(value)) {
        setSendAmount(value);
    }
  };

  //const { data: approveAData, writeContractAsync: approveATx, isPending: isApprovingA, error: approveAError } = useWriteContract();


  const handleRecipientChange = (e) => {
    const value = e.target.value;
    setRecipientAddress(value); // Update the address input state
    setRecipientTouched(true); // Mark as touched on change

    // Validate using viem's isAddress
    if (value && isAddress(value)) {
      setIsRecipientValid(true);
    } else {
      setIsRecipientValid(false);
    }
  };

  // Optional: Handler for when the input loses focus (onBlur)
  const handleRecipientBlur = () => {
      setRecipientTouched(true); // Mark as touched on blur too
  }

  return (
    <div className="bg-gray-800 rounded-xl p-4 max-w-md mx-auto mt-8 text-white justify-center">

        <div className="bg-gray-800 text-white p-4 max-w-md mx-auto rounded-xl">
          {isConnected && <span>Balance: {isLoadingBalance ? '...' : balance?.formatted ?? '0.0'} {tokenToSend}</span>}
          <div className="text-center text-gray-400 mb-2 text-sm">You are sending</div>
          <div className="bg-gray-900 p-3 rounded-xl flex justify-between mb-4 self-center">
              <input
              type="text"
              value={sendAmount}
              onChange={handleAmountChange}
              placeholder="0.00"
              className="w-full bg-gray-900 rounded p-2 text-center outline-none"
              />
              <select
                  value={tokenToSend}
                  onChange={(e) => handleTokenChange(e.target.value)}
                  className="bg-gray-700 rounded-xl p-2">

                  <option value="ETH">sETH</option>
                  
          </select>
          </div>
      
       {/* To section */}
          <div className="mb-6">
            <div className="text-center text-gray-400 mb-4 text-sm">To</div> 
              <input
                type="text"
                value={recipientAddress}
                onChange={handleRecipientChange} 
                onBlur={handleRecipientBlur}
                placeholder="provide wallet address" 
                className={`w-full bg-gray-900 border ${
                  recipientTouched && !isRecipientValid && recipientAddress // Show red border only if touched, not empty, and invalid
                    ? 'border-red-500 focus:border-red-500 focus:ring-red-500' // Invalid style
                    : 'border-gray-900 focus:border-emerald-500 focus:ring-emerald-500' // Default/valid style
                } rounded-lg p-2 text-center text-base font-mono transition-colors duration-150 outline-none focus:ring-1`} // Added focus styles, mono font
                aria-invalid={recipientTouched && !isRecipientValid && !!recipientAddress} // Accessibility
              />
              {/* Optional: Show error message */}
              {recipientTouched && !isRecipientValid && recipientAddress && (
                <p className="text-red-500 text-xs text-center mt-1">Please enter a valid Ethereum address.</p>
              )}
          </div>
        </div>

      
        <button
        className={`w-full py-3 rounded-xl font-bold ${
          // Check isRecipientValid here
          isConnected && sendAmount && isRecipientValid
            ? 'bg-gradient-to-r from-emerald-600 to-green-500 hover:from-emerald-700 hover:to-green-600' // Added hover
            : 'bg-gray-900 text-gray-500 cursor-not-allowed' // Updated disabled style
        } transition duration-200 ease-in-out`}
        // Update disabled check
        disabled={!isConnected || !sendAmount || !isRecipientValid}
      >
        {!isConnected
          ? "Connect Wallet"
          : !sendAmount
          ? "Enter an amount"
          : !recipientAddress // Keep check for empty input first
          ? "Enter recipient"
          : !isRecipientValid // Add check for validity
          ? "Invalid Address"
          : "Send"}
      </button>
    </div>
  );
}