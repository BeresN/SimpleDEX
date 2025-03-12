'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';
import Link from 'next/link';

export default function Navbar() {
  return (
    <nav className="flex justify-between items-center p-4 bg-gray-900 text-white">
      <div className="flex items-center">
        <Link href="/" className="text-xl font-bold">UniswapClone</Link>
        <div className="ml-8 space-x-4">
          <Link href="/swap" className="hover:text-pink-500 transition">Swap</Link>
          <Link href="/pool" className="hover:text-pink-500 transition">Pool</Link>
          <Link href="/vote" className="hover:text-pink-500 transition">Vote</Link>
          <Link href="/charts" className="hover:text-pink-500 transition">Charts</Link>
        </div>
      </div>
      <ConnectButton />
    </nav>
  );
}