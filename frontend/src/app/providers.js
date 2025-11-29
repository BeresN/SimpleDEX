"use client";

import Web3Provider from "@/components/Web3Provider";
import "./globals.css";

export function Providers({ children }) {
  return <Web3Provider>{children}</Web3Provider>;
}
