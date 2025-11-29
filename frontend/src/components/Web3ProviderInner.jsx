"use client";

import { useState } from "react";
import "@rainbow-me/rainbowkit/styles.css";
import { RainbowKitProvider, darkTheme, getDefaultConfig } from "@rainbow-me/rainbowkit";
import { WagmiProvider } from "wagmi";
import { sepolia } from "wagmi/chains";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";

const config = getDefaultConfig({
  appName: "SimpleDEX",
  projectId: "1b3a726e2fb752ad32e2efc2cb75b595",
  chains: [sepolia],
  ssr: true, // Enable SSR support
});

export default function Web3ProviderInner({ children }) {
  const [queryClient] = useState(() => new QueryClient({
    defaultOptions: {
      queries: {
        refetchOnWindowFocus: false,
        retry: false,
      },
    },
  }));

  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider theme={darkTheme()}>
          {children}
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
