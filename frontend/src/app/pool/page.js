// pages/pool.js
import Navbar from '../components/Navbar';
import LiquidityInterface from '../components/LiquidityInterface';

import '../style.css';  // Adjust path as needed
import "tailwindcss";

export default function Pool() {
  return (
    <div className="min-h-screen bg-gray-900">
      <Navbar />
      <main className="container mx-auto py-8 px-4">
        <h1 className="text-3xl font-bold text-center text-white mb-8">Liquidity Pool</h1>
      <LiquidityInterface/>
      </main>
    </div>
  );
}