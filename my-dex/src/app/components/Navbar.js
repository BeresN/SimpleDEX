'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';
import Link from 'next/link';

export default function Navbar() {
  return (
    <nav className="flex justify-between p-4 bg-gray-900 text-white">
      <div className="flex items-center">
        <div className="text-xl flex font-bold bg-gradient-to-r from-pink-500 to-purple-500">mySimpleDEX</div>
        <div className="ml-8 flex space-x-4">
          <Link href="/">Home</Link>
          <Link href="/pool">Pool</Link>
          <Link href="/swap">Swap</Link>
          <Link href="/send">Send</Link>
        </div>
        
      </div>
      <ConnectButton className="connect-button"/>
    </nav>
  );
}