// pages/pool.js
"use client";

import Navbar from "../components/Navbar";
import LiquidityInterface from "../components/LiquidityInterface";
import LiquidityPositions from "../components/LiquidityPositions";
import "../style.css";

export const dynamic = 'force-dynamic';

export default function Pool() {
  return (
    <div className="min-h-screen">
      <Navbar />
      <main className="container mx-auto py-12 px-4 space-y-8">
        <LiquidityInterface />
        <LiquidityPositions />
      </main>
    </div>
  );
}
