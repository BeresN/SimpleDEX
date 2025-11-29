"use client";

import Navbar from "../components/Navbar";
import SwapInterface from "../components/SwapInterface";
import "../style.css";

export const dynamic = 'force-dynamic';

export default function Swap() {
  return (
    <div className="min-h-screen">
      <Navbar />
      <main className="container mx-auto py-12 px-4">
        <SwapInterface />
      </main>
    </div>
  );
}
