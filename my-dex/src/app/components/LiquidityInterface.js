'use client';

import { useState, useEffect } from 'react';
import { useAccount, useBalance, useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseUnits, formatUnits, MaxUint256 } from 'viem';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import "tailwindcss";

// --- !!! CONFIGURE THESE !!! ---
const LIQUIDITY_POOL_ADDRESS = '0x...'; // Your Liquidity Pool Contract Address
const TOKEN_A_ADDRESS = '0x...';        // Your Token A Address
const TOKEN_B_ADDRESS = '0x...';        // Your Token B Address
const TOKEN_A_SYMBOL = 'sETH';           // Symbol for Token A
const TOKEN_B_SYMBOL = 'SEI';           // Symbol for Token B
const LP_TOKEN_SYMBOL = 'LPTK';           // Symbol for LP Token
// --- END CONFIGURATION ---

const InputField = ({ label, value, onChange, placeholder, balance, symbol, onMaxClick, disabled }) => (
  <div className="bg-gray-900 p-4 rounded-xl mb-2">
    <div className="flex justify-between items-center mb-2 text-xs text-gray-400">
      <span>{label}</span>
      {balance && (
        <div className='flex items-center'>
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
  const [viewMode, setViewMode] = useState('add'); 
  const [amountA, setAmountA] = useState('');
  const [amountB, setAmountB] = useState('');
  const [lpAmount, setLpAmount] = useState('');

  const { address, isConnected } = useAccount();

  // --- Wagmi Hooks ---
  const { data: balanceA, isLoading: isLoadingBalanceA } = useBalance({ address, token: TOKEN_A_ADDRESS, watch: true });
  const { data: balanceB, isLoading: isLoadingBalanceB } = useBalance({ address, token: TOKEN_B_ADDRESS, watch: true });
  const { data: balanceLP, isLoading: isLoadingBalanceLP } = useBalance({ address, token: LIQUIDITY_POOL_ADDRESS, watch: true }); // LP token IS the pool contract

  // Read Allowances
  const { data: allowanceA, refetch: refetchAllowanceA } = useReadContract({
    address: TOKEN_A_ADDRESS,
    functionName: 'allowance',
    args: [address, LIQUIDITY_POOL_ADDRESS],
    enabled: isConnected,
  });
  const { data: allowanceB, refetch: refetchAllowanceB } = useReadContract({
    address: TOKEN_B_ADDRESS,
    functionName: 'allowance',
    args: [address, LIQUIDITY_POOL_ADDRESS],
    enabled: isConnected,
  });

  // Contract Write Hooks
  const { data: approveAData, writeContractAsync: approveATx, isPending: isApprovingA, error: approveAError } = useWriteContract();
  const { data: approveBData, writeContractAsync: approveBTx, isPending: isApprovingB, error: approveBError } = useWriteContract();
  const { data: addLiqData, writeContractAsync: addLiquidityTx, isPending: isAddingLiquidity, error: addLiqError } = useWriteContract();
  const { data: remLiqData, writeContractAsync: removeLiquidityTx, isPending: isRemovingLiquidity, error: remLiqError } = useWriteContract();

   // Monitor approval A tx receipt
   const { isLoading: isConfirmingApproveA, isSuccess: isSuccessApproveA } = useWaitForTransactionReceipt({ hash: approveAData?.hash });
   // Monitor approval B tx receipt
   const { isLoading: isConfirmingApproveB, isSuccess: isSuccessApproveB } = useWaitForTransactionReceipt({ hash: approveBData?.hash });

   // Refetch allowances after successful approval confirmations
   useEffect(() => {
     if (isSuccessApproveA) refetchAllowanceA();
   }, [isSuccessApproveA, refetchAllowanceA]);

   useEffect(() => {
     if (isSuccessApproveB) refetchAllowanceB();
   }, [isSuccessApproveB, refetchAllowanceB]);


  // State & Logic
  const needsApprovalA = () => {
    if (!isConnected || !amountA || !balanceA || !allowanceA) return false;
    try {
      const amountAWei = parseUnits(amountA, balanceA.decimals);
      return allowanceA < amountAWei;
    } catch { return false; } // Handle invalid input format
  };
  const needsApprovalB = () => {
    if (!isConnected || !amountB || !balanceB || !allowanceB) return false;
    try {
      const amountBWei = parseUnits(amountB, balanceB.decimals);
      return allowanceB < amountBWei;
    } catch { return false; } // Handle invalid input format
  };

  const isApprovalPending = isApprovingA || isConfirmingApproveA || isApprovingB || isConfirmingApproveB;
  const isProcessing = isApprovalPending || isAddingLiquidity || isRemovingLiquidity;


  const handleAmountChange = (setter) => (e) => {
    const value = e.target.value;
    if (/^\d*\.?\d*$/.test(value)) {
      setter(value);
    }
  };


  const handleApprove = async (tokenAddress, approveTxFn) => {
    if (!isConnected) return;
    try {
      await approveTxFn({
        address: tokenAddress,
        functionName: 'approve',
        args: [LIQUIDITY_POOL_ADDRESS, MaxUint256], // Approve MAX
      });
      // No need to refetch here, useEffect handles it after confirmation
    } catch (err) {
      console.error("Approval failed:", err);
      // Show error to user
    }
  };

  const handleAddLiquidity = async () => {
    if (!isConnected || !amountA || !amountB || !balanceA || !balanceB || needsApprovalA() || needsApprovalB()) return;
    try {
      const amountAWei = parseUnits(amountA, balanceA.decimals);
      const amountBWei = parseUnits(amountB, balanceB.decimals);

      // Basic balance check (more robust checks recommended)
      if (amountAWei > balanceA.value || amountBWei > balanceB.value) {
         alert("Insufficient balance."); // Use better notifications
         return;
      }

      await addLiquidityTx({
        address: LIQUIDITY_POOL_ADDRESS,
        functionName: 'addLiquidity',
        args: [amountAWei, amountBWei], // Contract expects uint128, viem handles BigInt conversion
      });
       // Optionally clear fields on success initiation
      // setAmountA('');
      // setAmountB('');
    } catch (err) {
      console.error("Add liquidity failed:", err);
      // Show error to user
    }
  };

  const handleRemoveLiquidity = async () => {
     if (!isConnected || !lpAmount || !balanceLP || parseFloat(lpAmount) <= 0) return;
     try {
       const lpAmountWei = parseUnits(lpAmount, balanceLP.decimals); // Assuming LP token has decimals

       if (lpAmountWei > balanceLP.value) {
           alert("Insufficient LP token balance."); // Use better notifications
           return;
       }

       await removeLiquidityTx({
         address: LIQUIDITY_POOL_ADDRESS,
         functionName: 'removeLiquidity',
         args: [lpAmountWei],
       });
       // Optionally clear field on success initiation
      // setLpAmount('');
     } catch (err) {
        console.error("Remove liquidity failed:", err);
        // Show error to user
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

      {/* Action Buttons */}
      <div className="mt-4 space-y-3">
         {needsApprovalA() && (
            <button
              onClick={() => handleApprove(TOKEN_A_ADDRESS, approveATx)}
              disabled={isProcessing || !isConnected}
              className="w-full py-3 rounded-xl font-semibold text-lg bg-blue-600 hover:bg-blue-700 text-white transition duration-200 disabled:opacity-50 disabled:cursor-not-allowed flex justify-center items-center"
            >
              {isApprovingA || isConfirmingApproveA ? <LoadingSpinner /> : `Approve ${TOKEN_A_SYMBOL}`}
            </button>
         )}
         {needsApprovalB() && (
            <button
              onClick={() => handleApprove(TOKEN_B_ADDRESS, approveBTx)}
              disabled={isProcessing || !isConnected}
               className="w-full py-3 rounded-xl font-semibold text-lg bg-blue-600 hover:bg-blue-700 text-white transition duration-200 disabled:opacity-50 disabled:cursor-not-allowed flex justify-center items-center"
            >
               {isApprovingB || isConfirmingApproveB ? <LoadingSpinner /> : `Approve ${TOKEN_B_SYMBOL}`}
            </button>
         )}
         {(!needsApprovalA() && !needsApprovalB()) && (
            <button
              onClick={handleAddLiquidity}
              disabled={isProcessing || !isConnected || !amountA || !amountB || parseFloat(amountA) <= 0 || parseFloat(amountB) <= 0}
              className="w-full py-3 rounded-xl font-semibold text-lg bg-emerald-600 hover:bg-emerald-700 text-white transition duration-200 disabled:bg-gray-700 disabled:text-gray-500 disabled:cursor-not-allowed flex justify-center items-center"
            >
              {isAddingLiquidity ? <LoadingSpinner /> : 'Add Liquidity'}
            </button>
         )}
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
         {/* You might want to display estimated amounts of Token A and B returned here */}
         {/* Requires reading reserves and doing calculations */}

         <div className="mt-3">
            <button
              onClick={handleRemoveLiquidity}
              disabled={isProcessing || !isConnected || !lpAmount || parseFloat(lpAmount) <= 0}
              className="w-full py-3 rounded-xl font-semibold text-lg bg-red-600 hover:bg-red-700 text-white transition duration-200 disabled:bg-gray-700 disabled:text-gray-500 disabled:cursor-not-allowed flex justify-center items-center"
            >
              {isRemovingLiquidity ? <LoadingSpinner /> : 'Remove Liquidity'}
            </button>
         </div>
      </>
   );


  return (
    <div className="bg-gray-800 rounded-2xl p-4 sm:p-5 max-w-md mx-auto mt-8 text-white border border-gray-700 shadow-lg">
      {/* Container for the header elements (ConnectButton on right) */}
      {/* Container for the header elements */}
      <div className="flex justify-between items-center mb-5">

        {/* Container for the vertically stacked view-switching buttons */}
        {/* --- TRY THIS VERSION --- */}
        {/* Using flex flex-col explicitly ensures vertical stacking */}
        <div className="flex flex-col space-y-2"> {/* ADDED flex and flex-col */}
           <button
              onClick={() => setViewMode('add')}
              // Ensure standard rounding (rounded-lg, not rounded-l-lg)
              className={`px-4 py-2 rounded-lg text-sm font-medium ${viewMode === 'add' ? 'bg-emerald-600 text-white' : 'bg-gray-700 text-gray-300 hover:bg-gray-600'}`}
              disabled={isProcessing}
           >
              Add Liquidity
           </button>
           <button
              onClick={() => setViewMode('remove')}
              // Ensure standard rounding (rounded-lg, not rounded-r-lg)
              className={`px-4 py-2 rounded-lg text-sm font-medium ${viewMode === 'remove' ? 'bg-red-600 text-white' : 'bg-gray-700 text-gray-300 hover:bg-gray-600'}`}
              disabled={isProcessing}
            >
              Remove Liquidity
            </button>
        </div>
        {/* --- END OF VERSION TO TRY --- */}


        {/* ConnectButton remains unchanged */}
        <ConnectButton showBalance={false} chainStatus="icon" accountStatus="address" />
      </div>

      {/* --- This conditional rendering logic remains exactly the same --- */}
      {!isConnected ? (
        <div className="text-center text-gray-400 py-8">Please connect your wallet.</div>
      ) : viewMode === 'add' ? (
        renderAddLiquidity() // Make sure this function is defined
      ) : (
        renderRemoveLiquidity() // Make sure this function is defined
      )}
      {/* --- End of unchanged logic --- */}
      {/* Transaction Feedback Area */}
       {isProcessing && <div className="mt-4 text-center text-sm text-yellow-400">Processing Transaction... Check Wallet</div>}
       {addLiqData && <TxFeedback hash={addLiqData.hash} successMessage="Liquidity Added!" />}
       {remLiqData && <TxFeedback hash={remLiqData.hash} successMessage="Liquidity Removed!" />}
       {approveAData && !isSuccessApproveA && <TxFeedback hash={approveAData.hash} successMessage={`${TOKEN_A_SYMBOL} Approved!`} pending />}
       {approveBData && !isSuccessApproveB && <TxFeedback hash={approveBData.hash} successMessage={`${TOKEN_B_SYMBOL} Approved!`} pending />}

      {/* Error Display */}
       { (approveAError || approveBError || addLiqError || remLiqError) && (
           <div className="mt-4 p-3 bg-red-900/50 border border-red-700 rounded-lg text-center text-red-300 text-xs break-words">
               Error: {(approveAError || approveBError || addLiqError || remLiqError)?.shortMessage || 'An error occurred.'}
           </div>
       )}

    </div>
  );
}


// Helper component for Transaction Feedback
const TxFeedback = ({ hash, successMessage, pending = false }) => {
   const { data: receipt, isLoading, isSuccess } = useWaitForTransactionReceipt({ hash });
   const explorerUrl = `https://etherscan.io/tx/${hash}`; // Replace with your network's explorer

   if (!hash) return null;

   return (
     <div className={`mt-4 p-2 border rounded-lg text-center text-xs sm:text-sm break-all ${
        isSuccess ? 'bg-green-900/50 border-green-700/50 text-green-300' :
        isLoading || pending ? 'bg-yellow-900/50 border-yellow-700/50 text-yellow-300' :
        'bg-gray-700 border-gray-600 text-gray-300' // Default or pending state
     }`}>
        {isSuccess ? successMessage : (isLoading || pending) ? 'Transaction Pending...' : 'Transaction Initiated'} <br/>
        <a href={explorerUrl} target="_blank" rel="noopener noreferrer" className="underline hover:text-white font-mono">
           {hash.substring(0, 6)}...{hash.substring(hash.length - 4)}
        </a>
        {isLoading && <span className='ml-2'><LoadingSpinner small /></span>}
     </div>
   );
}

// Simple Loading Spinner
const LoadingSpinner = ({ small = false }) => (
  <svg className={`animate-spin ${small ? 'h-4 w-4' : 'h-5 w-5'} text-white inline-block`} xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
  </svg>
);