"use client";

import Link from "next/link";
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { ArrowRight, Droplets, ArrowLeftRight, TrendingUp, Shield, Zap } from "lucide-react";
import Navbar from "./components/Navbar";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import "./style.css";
import "tailwindcss";

export const dynamic = 'force-dynamic';

export default function Home() {
  const features = [
    {
      icon: ArrowLeftRight,
      title: "Easy Token Swaps",
      description: "Instantly swap tokens with competitive rates and minimal slippage.",
    },
    {
      icon: Droplets,
      title: "Provide Liquidity",
      description: "Earn trading fees by providing liquidity to our pools.",
    },
    {
      icon: Shield,
      title: "Secure & Trustless",
      description: "Non-custodial trading directly from your wallet.",
    },

  ];

  return (
    <div className="min-h-screen">
      <Navbar />

      <main className="container mx-auto py-12 px-4">
        {/* Hero Section */}
        <section className="text-center mb-20 pt-8">
          <h1 className="text-4xl md:text-6xl font-bold mb-6 bg-gradient-to-r from-primary via-primary/80 to-primary/60 bg-clip-text text-transparent">
            Welcome to SimpleDEX
          </h1>
          <p className="text-lg md:text-xl text-muted-foreground mb-8 max-w-2xl mx-auto">
            The simplest decentralized exchange for swapping tokens and providing liquidity.
            Trade directly from your wallet without intermediaries.
          </p>
          <div className="flex flex-col sm:flex-row justify-center gap-4 mb-12">
            <Link href="/swap">
              <Button size="lg" className="gap-2">
                Start Trading
                <ArrowRight className="h-4 w-4" />
              </Button>
            </Link>
            <Link href="/pool">
              <Button size="lg" variant="outline" className="gap-2">
                <Droplets className="h-4 w-4" />
                Add Liquidity
              </Button>
            </Link>
          </div>
        </section>

        {/* Features Section */}
        <section className="mb-20">
          <div className="text-center mb-12">
            <h2 className="text-3xl md:text-4xl font-bold mb-4">Why Choose SimpleDEX?</h2>
            <p className="text-muted-foreground max-w-2xl mx-auto">
              Experience the future of decentralized finance with our cutting-edge platform
            </p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {features.map((feature, index) => {
              const Icon = feature.icon;
              return (
                <Card key={index} className="border-2 hover:border-primary/50 transition-colors">
                  <CardHeader>
                    <div className="h-12 w-12 rounded-lg bg-primary/10 flex items-center justify-center mb-4">
                      <Icon className="h-6 w-6 text-primary" />
                    </div>
                    <CardTitle>{feature.title}</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <CardDescription>{feature.description}</CardDescription>
                  </CardContent>
                </Card>
              );
            })}
          </div>
        </section>

        {/* How It Works Section */}
        <section className="mb-20">
          <Card className="border-2">
            <CardHeader>
              <CardTitle className="text-center text-2xl md:text-3xl">How SimpleDEX Works</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
                <div className="text-center space-y-3">
                  <div className="h-16 w-16 bg-gradient-to-br from-primary to-primary/60 rounded-full flex items-center justify-center mx-auto">
                    <span className="text-2xl font-bold text-primary-foreground">1</span>
                  </div>
                  <h3 className="text-lg font-semibold">Connect Wallet</h3>
                  <p className="text-muted-foreground text-sm">
                    Connect your wallet to start trading or providing liquidity.
                  </p>
                </div>
                <div className="text-center space-y-3">
                  <div className="h-16 w-16 bg-gradient-to-br from-primary to-primary/60 rounded-full flex items-center justify-center mx-auto">
                    <span className="text-2xl font-bold text-primary-foreground">2</span>
                  </div>
                  <h3 className="text-lg font-semibold">Swap or Add Liquidity</h3>
                  <p className="text-muted-foreground text-sm">
                    Exchange tokens or add liquidity to earn trading fees.
                  </p>
                </div>
                <div className="text-center space-y-3">
                  <div className="h-16 w-16 bg-gradient-to-br from-primary to-primary/60 rounded-full flex items-center justify-center mx-auto">
                    <span className="text-2xl font-bold text-primary-foreground">3</span>
                  </div>
                  <h3 className="text-lg font-semibold">Earn & Manage</h3>
                  <p className="text-muted-foreground text-sm">
                    Earn fees from trading or withdraw your assets anytime.
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
        </section>

        {/* CTA Section */}
        <section className="text-center py-12">
          <Card className="border-2 bg-gradient-to-br from-primary/5 to-primary/10">
            <CardContent className="pt-6">
              <h2 className="text-2xl md:text-3xl font-bold mb-4">Ready to get started?</h2>
              <p className="text-muted-foreground mb-6 max-w-xl mx-auto">
                Join thousands of users trading on SimpleDEX today
              </p>
              <Link href="/swap">
                <Button size="lg" className="gap-2">
                  Start Trading Now
                  <ArrowRight className="h-4 w-4" />
                </Button>
              </Link>
            </CardContent>
          </Card>
        </section>
      </main>
    </div>
  );
}
