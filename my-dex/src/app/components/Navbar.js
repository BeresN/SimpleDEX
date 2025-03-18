'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';
import Link from 'next/link';

export default function Navbar() {
  return (
    <nav className="flex justify-between p-4 bg-gray-900 text-white">
      <div className="flex items-center">
        <Link href="/" className="text-xl flex font-bold bg-gradient-to-r from-pink-500 to-purple-500">mySimpleDEX</Link>
        <div className="ml-8 flex space-x-4">
          <Link href="/swap" className="text-white hover:bg-pink-600 font-medium rounded-lg text-sm px-4 py-2 transition">Pool</Link>
          <Link href="/pool" className="text-white hover:bg-pink-600 font-medium rounded-lg text-sm px-4 py-2 transition">Swap</Link>
          <Link href="/vote" className="text-white hover:bg-pink-600 font-medium rounded-lg text-sm px-4 py-2 transition">Vote</Link>
          <Link href="/charts" className="text-white hover:bg-pink-600 font-medium rounded-lg text-sm px-4 py-2 transition">Charts</Link>
          
        </div>
        
      </div>
      <ConnectButton className="connect-button"/>
    </nav>
  );
}