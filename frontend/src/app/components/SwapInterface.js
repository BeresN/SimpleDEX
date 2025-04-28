'use client';

import { useState } from 'react';
import { useAccount, useBalance } from 'wagmi';
import "tailwindcss";

export default function SwapInterface() {
  const [fromToken, setFromToken] = useState("sETH");
  const [toToken, setToToken] = useState("sOP");
  const [fromAmount, setFromAmount] = useState("");
  const [toAmount, setToAmount] = useState("");
  const { address, isConnected } = useAccount();
  const { data: balance } = useBalance({
    address,
    token: fromToken === "ETH" ? undefined : "0xTokenAddress", // Replace with actual token address
  });

  const handleSwapTokens = () => {
    setFromToken(toToken);
    setToToken(fromToken);
    setFromAmount(toAmount);
    setToAmount(fromAmount);
  };
  
  const handleFromAmountChange = (e) => {
    const value = e.target.value;
    setFromAmount(value);
    // Mock price calculation - in a real app this would use actual exchange rates
    setToAmount(value * (fromToken === "ETH" ? 1800 : 1/1800));
  };

  return (
    <div className="bg-gray-800 rounded-xl p-4 max-w-md mx-auto mt-8 text-white justify-center">
      <div className="mb-4">
        {isConnected && <span>Balance: {balance?.formatted || "0.000"} {fromToken}</span>}
        <div className="mb-2">
          <span>Sell </span>
        </div>
        <div className="bg-gray-900 p-3 rounded-xl flex justify-between self-center">
          <input
            type="text"
            value={fromAmount}
            onChange={handleFromAmountChange}
            placeholder="0.0"
            className="bg-transparent outline-none w-2/3"
          />
          <select
            value={fromToken}
            onChange={(e) => handleSwapTokens(e.target.value)}
            className="bg-gray-700 rounded-xl p-2"
          >
            <option value="ETH">sETH</option>
            <option value="sOP">sOP</option>
            
          </select>
        </div>
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
          <select
            value={toToken}
            onChange={(e) => handleSwapTokens(e.target.value)}
            className="bg-gray-700 rounded-xl p-2"
          >
            <option value="ETH">sETH</option>
            <option value="sOP">sOP</option>
            
          </select>
        </div>
      </div>
      
      <button
        className={`w-full py-3 rounded-xl font-bold ${
          isConnected ? 'g-gradient-to-r from-emerald-600 to-green-500' : 'bg-gray-600'
        } transition`}
        disabled={!isConnected}
      >
        {isConnected ? "Swap" : "Connect Wallet to Swap"}
      </button>
    </div>
  );
}