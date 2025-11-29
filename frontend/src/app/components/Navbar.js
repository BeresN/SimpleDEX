'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';
import Link from 'next/link';
import { useState } from 'react';
import { usePathname } from 'next/navigation';
import { Menu, X, Home, Droplets, ArrowLeftRight, Send } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';
import "tailwindcss";

export default function Navbar() {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const pathname = usePathname();

  const navItems = [
    { href: '/', label: 'Home', icon: Home },
    { href: '/pool', label: 'Pool', icon: Droplets },
    { href: '/swap', label: 'Swap', icon: ArrowLeftRight },
    { href: '/send', label: 'Send', icon: Send },
  ];

  const isActive = (path) => pathname === path;

  return (
    <nav className="sticky top-0 z-50 border-b border-border/40 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <Link href="/" className="flex items-center gap-2 group">
            <div className="h-8 w-8 rounded-lg bg-gradient-to-br from-primary to-primary/60 flex items-center justify-center">
              <Droplets className="h-5 w-5 text-primary-foreground" />
            </div>
            <span className="text-xl font-bold bg-gradient-to-r from-primary to-primary/60 bg-clip-text text-transparent">
              SimpleDEX
            </span>
          </Link>

          {/* Desktop Navigation */}
          <div className="hidden md:flex items-center gap-1">
            {navItems.map((item) => {
              const Icon = item.icon;
              return (
                <Link key={item.href} href={item.href}>
                  <Button
                    variant={isActive(item.href) ? 'secondary' : 'ghost'}
                    className={cn(
                      'gap-2',
                      isActive(item.href) && 'bg-primary/10 text-primary hover:bg-primary/20'
                    )}
                  >
                    <Icon className="h-4 w-4" />
                    {item.label}
                  </Button>
                </Link>
              );
            })}
          </div>

          {/* Desktop Wallet Connection */}
          <div className="hidden md:block">
            <ConnectButton
              showBalance={true}
              chainStatus="icon"
              accountStatus="address"
            />
          </div>

          {/* Mobile Menu Button */}
          <Button
            variant="ghost"
            size="icon"
            className="md:hidden"
            onClick={() => setIsMenuOpen(!isMenuOpen)}
          >
            {isMenuOpen ? (
              <X className="h-5 w-5" />
            ) : (
              <Menu className="h-5 w-5" />
            )}
          </Button>
        </div>

        {/* Mobile Navigation */}
        {isMenuOpen && (
          <div className="md:hidden py-4 space-y-3 border-t border-border/40">
            {navItems.map((item) => {
              const Icon = item.icon;
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  onClick={() => setIsMenuOpen(false)}
                >
                  <Button
                    variant={isActive(item.href) ? 'secondary' : 'ghost'}
                    className={cn(
                      'w-full justify-start gap-2',
                      isActive(item.href) && 'bg-primary/10 text-primary hover:bg-primary/20'
                    )}
                  >
                    <Icon className="h-4 w-4" />
                    {item.label}
                  </Button>
                </Link>
              );
            })}
            <div className="pt-3 border-t border-border/40">
              <ConnectButton
                showBalance={true}
                chainStatus="icon"
                accountStatus="address"
              />
            </div>
          </div>
        )}
      </div>
    </nav>
  );
}