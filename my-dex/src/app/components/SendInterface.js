'use client';
import { useState } from 'react';
import { useAccount, useBalance } from 'wagmi';
import "tailwindcss";

const TOKEN_ADDRESSES = {
    // Example: Replace 'SEI_TOKEN_ADDRESS' with the actual contract address
    SEI: '0x...', // Replace with SEI Token Address on the relevant network
    // Add other tokens as needed
  };

export default function SendInterface() {
    const [tokenToSend, setTokenToSend] = useState("sETH");
    const [sendAmount, setSendAmount] = useState("");
    const [recipientAddress, setRecipientAddress] = useState(""); // Assuming you have this state elsewhere
    const { address, isConnected } = useAccount();
    const { data: balance, isLoading: isLoadingBalance } = useBalance({
      address,
      token: tokenToSend === "ETH" ? undefined : TOKEN_ADDRESSES[tokenToSend],
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

  return (
    <div className="bg-gray-900 rounded-xl p-4 max-w-md mx-auto mt-8 text-white justify-center">

        <div className="bg-gray-900 text-white p-4 max-w-md mx-auto rounded-xl">
        {/* You send section */}
        <div className="mb-6">
            <div className="text-center mb-2">You send</div>
            <input
            type="text"
            value={sendAmount}
            onChange={handleAmountChange}
            placeholder="0"
            className="w-full bg-transparent border border-gray-800 rounded p-2 text-center"
            />
        </div>
        
        {/* Back button and token selector */}
        <div className="bg-gray-900 p-3 rounded-xl justify-between self-center">
        <select
                value={tokenToSend}
                onChange={(e) => handleTokenChange(e.target.value)}
                className="bg-gray-700 rounded-xl p-2">
                <option value="ETH">sETH</option>
                <option value="SEI">SEI</option>
                
        </select>
        </div>
        
        {/* To section */}
        <div className="mb-6">
            <div className="text-center mb-2">To</div>
            <input
            type="text"
            value={recipientAddress}
            onChange={(e) => setRecipientAddress(e.target.value)}
            placeholder="Wallet address or ENS name"
            className="w-full bg-transparent border border-gray-800 rounded p-2 text-center"
            />
        </div>
      </div>

      
      <button
        className={`w-full py-3 rounded-xl font-bold ${
          isConnected && sendAmount && recipientAddress
            ? 'bg-gradient-to-r from-emerald-600 to-green-500'
            : 'bg-gray-600'
        } transition`}
        disabled={!isConnected || !sendAmount || !recipientAddress}
      >
        {!isConnected
          ? "Connect Wallet"
          : !sendAmount
          ? "Enter an amount"
          : !recipientAddress
          ? "Enter recipient"
          : "Send"}
      </button>
    </div>
  );
}