import Head from 'next/head';
import Navbar from '../components/Navbar';
import SwapInterface from '../components/SwapInterface';

export default function Home() {
  return (
    <div className="min-h-screen bg-gray-900">
      <Head>
        <title>UniswapClone - Decentralized Exchange</title>
        <meta name="description" content="A decentralized exchange like Uniswap" />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <Navbar />
      
      <main className="container mx-auto py-8 px-4">
        <h1 className="text-3xl font-bold text-center text-white mb-8">Swap tokens instantly</h1>
        <SwapInterface />
        
        <div className="mt-12 grid grid-cols-1 md:grid-cols-3 gap-8 text-white">
          <div className="bg-gray-800 p-6 rounded-xl">
            <h2 className="text-xl font-bold mb-4">Trusted by millions</h2>
            <p>Secure, reliable token swaps with deep liquidity and competitive rates.</p>
          </div>
          <div className="bg-gray-800 p-6 rounded-xl">
            <h2 className="text-xl font-bold mb-4">Low fees</h2>
            <p>Trade with minimal fees and maximum efficiency on multiple networks.</p>
          </div>
          <div className="bg-gray-800 p-6 rounded-xl">
            <h2 className="text-xl font-bold mb-4">Community governed</h2>
            <p>Built and run by a global community of token holders and developers.</p>
          </div>
        </div>
      </main>
    </div>
  );
}