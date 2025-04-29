'use client';

import { useState } from 'react';
import { useAccount, useBalance, useWriteContract } from 'wagmi';
import { erc20Abi } from 'viem';
import { MaxUint256 } from 'ethers';
import "tailwindcss";
import swapAbi from '../../../abis/swapAbi.json';


const TOKEN_A_ADDRESS= '0x558f6e1BFfD83AD9F016865bF98D6763566d49c6';    
const TOKEN_B_ADDRESS= '0x4DF4493209006683e678983E1Ec097680AB45e13';
const SWAP_CONTRACT_ADDRESS= '0x128dcb97c60033fC091440aA4EBB0F20A8034889'; 
const TOKEN_A_SYMBOL = 'mETH';        
const TOKEN_B_SYMBOL = 'mSEI';   

export default function SwapInterface() {
  const [fromToken, setFromToken] = useState("mETH");
  const [toToken, setToToken] = useState("mSEI");
  const [fromAmount, setFromAmount] = useState("");
  const [toAmount, setToAmount] = useState("");
  const { address, isConnected } = useAccount();
  const { writeContract, isPending, isSuccess, isError, error } = useWriteContract();

  const { data: balanceA, isLoading: isLoadingBalanceA } = useBalance({ address, token: TOKEN_A_ADDRESS, watch: true });
  const { data: balanceB, isLoading: isLoadingBalanceB } = useBalance({ address, token: TOKEN_B_ADDRESS, watch: true });

  const currentBalanceData = fromToken === TOKEN_A_SYMBOL ? balanceA : balanceB;

  const handleSwapTokens = () => {
    setFromToken(toToken);
    setToToken(fromToken);
    setFromAmount(toAmount);
    setToAmount(fromAmount);
  };

  const handleSwap = () => {
    if (!isConnected || !fromAmount) return;
  
    writeContract({
      address: SWAP_CONTRACT_ADDRESS,
      abi: swapAbi,
      functionName: 'swap',
      args: [
        fromToken === TOKEN_A_SYMBOL ? fromAmount : 0,
        fromToken === TOKEN_B_SYMBOL ? fromAmount : 0,
        address
      ],
    });
  };
  
  const handleFromAmountChange = (e) => {
    const value = e.target.value;
    setFromAmount(value);
    // Mock price calculation - in a real app this would use actual exchange rates
    setToAmount(value * (fromToken === "mETH" ? 1 : 1/2));
  };

  return (
    <div className="bg-gray-800 rounded-xl p-4 max-w-md mx-auto mt-8 text-white justify-center">
      <div className="mb-4">
      Balance: {currentBalanceData ? currentBalanceData.formatted : '0.00' }
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
            value={toToken}
            onChange={(e) => handleSwapTokens(e.target.value)}
            className="bg-gray-700 rounded-xl p-2"
          >
            <option value="TOKEN_A_SYMBOL">mETH</option>
            <option value="TOKEN_B_SYMBOL">mSEI</option>
            
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
            value={fromToken}
            onChange={(e) => handleSwapTokens(e.target.value)}
            className="bg-gray-700 rounded-xl p-2"
          >
            <option value="TOKEN_B_SYMBOL">mSEI</option>
            <option value="TOKEN_A_SYMBOL">mETH</option>
            
            
          </select>
        </div>
      </div>
      
      <button
        onClick={handleSwap}
        className={`w-full py-3 rounded-xl font-bold ${
          isConnected && fromAmount ? 'bg-gradient-to-r from-emerald-600 to-green-500 hover:from-emerald-700 hover:to-green-600' // Added hover
          : 'bg-gray-900 text-gray-500 cursor-not-allowed' // Updated disabled style
        } transition`}
        disabled={!isConnected || !fromAmount || !isPending}
      >
        {isPending ? "Swapping..." : isConnected ? "Swap" : "Connect Wallet to Swap"}

      </button>
      {isSuccess && <div>Transaction successful!</div>}
      {isError && <div>Error: {error.message}</div>}
    </div>
  );
}