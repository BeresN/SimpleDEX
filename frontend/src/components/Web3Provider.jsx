"use client";

import "@rainbow-me/rainbowkit/styles.css";
import Web3ProviderInner from "./Web3ProviderInner";

export default function Web3Provider({ children }) {
  return <Web3ProviderInner>{children}</Web3ProviderInner>;
}
