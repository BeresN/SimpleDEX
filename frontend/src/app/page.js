import Navbar from "./components/Navbar";
import SwapInterface from "./components/SwapInterface";
import LiquidityInterface from "./components/LiquidityInterface";
import { ConnectButton } from '@rainbow-me/rainbowkit';

import "./style.css";
import "tailwindcss";

export default function Home() {
  return (
    <div className="min-h-screen bg-gray-900">
      <Navbar />

      <main className="container mx-auto py-8 px-4">
        {/* Hero Section */}
        <section className="text-center mb-12">
          <h1 className="text-4xl md:text-5xl font-bold text-white mb-4">
            Welcome to SimpleDEX
          </h1>
          <p className="text-xl text-gray-300 mb-8 max-w-2xl mx-auto">
            The simplest decentralized exchange for swapping tokens and providing liquidity.
            Trade directly from your wallet without intermediaries.
          </p>
          <div className="flex justify-center gap-4">
            <ConnectButton
              showBalance={true}
              chainStatus="icon"
              accountStatus="address"
            />
          </div>
        </section>
        {/* Educational Section */}
        <section className="bg-gray-800 rounded-2xl p-8 mb-12">
          <h2 className="text-2xl font-bold text-white mb-6 text-center">How SimpleDEX Works</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="text-center">
              <div className="w-12 h-12 bg-emerald-600 rounded-full flex items-center justify-center mx-auto mb-4">
                <span className="text-white font-bold">1</span>
              </div>
              <h3 className="text-lg font-semibold text-white mb-2">Connect Wallet</h3>
              <p className="text-gray-400">Connect your wallet to start trading or providing liquidity.</p>
            </div>
            <div className="text-center">
              <div className="w-12 h-12 bg-emerald-600 rounded-full flex items-center justify-center mx-auto mb-4">
                <span className="text-white font-bold">2</span>
              </div>
              <h3 className="text-lg font-semibold text-white mb-2">Swap or Add Liquidity</h3>
              <p className="text-gray-400">Exchange tokens or add liquidity to earn trading fees.</p>
            </div>
            <div className="text-center">
              <div className="w-12 h-12 bg-emerald-600 rounded-full flex items-center justify-center mx-auto mb-4">
                <span className="text-white font-bold">3</span>
              </div>
              <h3 className="text-lg font-semibold text-white mb-2">Earn & Manage</h3>
              <p className="text-gray-400">Earn fees from trading or withdraw your assets anytime.</p>
            </div>
          </div>
        </section>
      </main>
    </div>
  );
}
