'use client';

import { useState } from 'react';
import { ArrowDown } from 'lucide-react';
import { useAccount, useBalance } from 'wagmi';

export default function SwapInterface() {
  const [fromToken, setFromToken] = useState("ETH");
  const [toToken, setToToken] = useState("USDC");
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
    <div className="bg-gray-800 rounded-xl p-4 max-w-md mx-auto mt-8 text-white">
      <div className="mb-4">
        <div className="flex justify-between mb-2">
          <span>From</span>
          {isConnected && <span>Balance: {balance?.formatted || "0"} {fromToken}</span>}
        </div>
        <div className="bg-gray-900 p-3 rounded-xl flex justify-between">
          <input
            type="number"
            value={fromAmount}
            onChange={handleFromAmountChange}
            placeholder="0.0"
            className="bg-transparent outline-none w-2/3"
          />
          <select
            value={fromToken}
            onChange={(e) => setFromToken(e.target.value)}
            className="bg-gray-700 rounded-xl p-2"
          >
            <option value="ETH">ETH</option>
            <option value="USDC">USDC</option>
            <option value="WBTC">WBTC</option>
            <option value="DAI">DAI</option>
          </select>
        </div>
      </div>
      
      <div className="flex justify-center my-2">
        <button
          onClick={handleSwapTokens}
          className="bg-gray-700 p-2 rounded-full hover:bg-gray-600 transition"
        >
          <ArrowDown size={20} />
        </button>
      </div>
      
      <div className="mb-4">
        <div className="flex justify-between mb-2">
          <span>To</span>
        </div>
        <div className="bg-gray-900 p-3 rounded-xl flex justify-between">
          <input
            type="number"
            value={toAmount}
            readOnly
            placeholder="0.0"
            className="bg-transparent outline-none w-2/3"
          />
          <select
            value={toToken}
            onChange={(e) => setToToken(e.target.value)}
            className="bg-gray-700 rounded-xl p-2"
          >
            <option value="ETH">ETH</option>
            <option value="USDC">USDC</option>
            <option value="WBTC">WBTC</option>
            <option value="DAI">DAI</option>
          </select>
        </div>
      </div>
      
      <button
        className={`w-full py-3 rounded-xl font-bold ${
          isConnected ? 'bg-pink-500 hover:bg-pink-600' : 'bg-gray-600'
        } transition`}
        disabled={!isConnected}
      >
        {isConnected ? "Swap" : "Connect Wallet to Swap"}
      </button>
    </div>
  );
}