'use client';

import '@rainbow-me/rainbowkit/styles.css';
import { RainbowKitProvider, darkTheme, getDefaultConfig } from '@rainbow-me/rainbowkit';
import { WagmiProvider } from 'wagmi';
import { mainnet, polygon, optimism, arbitrum, sepolia, etherlinkTestnet } from 'viem/chains';
import { http } from 'viem';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import './globals.css';


// Create the wagmi config using RainbowKit's helper function
const config = getDefaultConfig({
  appName: 'My own dex',
  projectId: '1b3a726e2fb752ad32e2efc2cb75b595',
  chains: [mainnet, sepolia, etherlinkTestnet, polygon, optimism, arbitrum],
  transports: {
    [mainnet.id]: http(),
    [sepolia.id]: http(),
    [etherlinkTestnet.id]: http(),
    [polygon.id]: http(),
    [optimism.id]: http(),
    [arbitrum.id]: http(),
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
