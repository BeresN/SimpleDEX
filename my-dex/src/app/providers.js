'use client';

import '@rainbow-me/rainbowkit/styles.css';
import { RainbowKitProvider, darkTheme, getDefaultConfig } from '@rainbow-me/rainbowkit';
import { WagmiProvider } from 'wagmi';
import { seiTestnet, sepolia } from 'viem/chains';
import { http } from 'viem';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import './globals.css';


// Create the wagmi config using RainbowKit's helper function
const config = getDefaultConfig({
  appName: 'My own dex',
  projectId: '1b3a726e2fb752ad32e2efc2cb75b595',
  chains: [sepolia, seiTestnet],
  transports: {
    [sepolia.id]: http(),
    [seiTestnet.id]: http(),
  },
});

// Initialize the Query Client
const queryClient = new QueryClient();

// Export the providers component
export function Providers({ children }) {
  return (
    <QueryClientProvider client={queryClient}>
      <WagmiProvider config={config}>
        <RainbowKitProvider theme={darkTheme()}>{children}</RainbowKitProvider>
      </WagmiProvider>
    </QueryClientProvider>
  );
}
