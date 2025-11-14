'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';
import Link from 'next/link';
import { useState } from 'react';
import "tailwindcss";

export default function Navbar() {
  const [isMenuOpen, setIsMenuOpen] = useState(false);

  return (
    <nav className="flex flex-col sm:flex-row justify-between p-4 bg-gray-900 text-white">
      <div className="flex justify-between items-center w-full">
        <div className="text-xl font-bold">mySimpleDEX</div>
        <button 
          className="sm:hidden text-white focus:outline-none z-50"
          onClick={() => setIsMenuOpen(!isMenuOpen)}
        >
          <svg 
            className="w-6 h-6" 
            fill="none" 
            stroke="currentColor" 
            viewBox="0 0 24 24" 
            xmlns="http://www.w3.org/2000/svg"
          >
            {isMenuOpen ? (
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            ) : (
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
            )}
          </svg>
        </button>
      </div>

      {/* Navigation Links - Hidden on mobile when menu is closed */}
      <div 
        className={`${
          isMenuOpen ? 'block' : 'hidden'
        } sm:block w-full sm:w-auto mt-2 sm:mt-0`}
      >
        <div className="flex flex-col sm:flex-row sm:items-center space-y-2 sm:space-y-0 sm:space-x-4">
          <div className="flex flex-col sm:flex-row sm:space-x-4 mb-2 sm:mb-0">
            <Link href="/" className="hover:text-gray-300 py-1 sm:py-0 text-center">Home</Link>
            <Link href="/pool" className="hover:text-gray-300 py-1 sm:py-0 text-center">Pool</Link>
            <Link href="/swap" className="hover:text-gray-300 py-1 sm:py-0 text-center">Swap</Link>
            <Link href="/send" className="hover:text-gray-300 py-1 sm:py-0 text-center">Send</Link>
          </div>
          <div className="w-full sm:w-auto">
            <ConnectButton
              showBalance={true}
              chainStatus="icon"
              accountStatus="address"
              className="w-full sm:w-auto"
            />
          </div>
        </div>
      </div>
    </nav>
  );
}