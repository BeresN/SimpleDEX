'use client';

import '@rainbow-me/rainbowkit/styles.css';
import { RainbowKitProvider, darkTheme } from '@rainbow-me/rainbowkit';
import { WagmiProvider } from 'wagmi';
import { mainnet, sepolia, etherlinkTestnet } from 'wagmi/chains';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { getDefaultWallets } from '@rainbow-me/rainbowkit';
import { createConfig, http } from 'wagmi';
import './globals.css';


// Initialize the Query Client
const queryClient = new QueryClient();

const { wallets } = getDefaultWallets({
  appName: 'My own dex',
  projectId: '1b3a726e2fb752ad32e2efc2cb75b595',
  chains: [mainnet, sepolia, etherlinkTestnet],
});


// Create wagmi config
const config = createConfig({
  chains: [mainnet, sepolia, etherlinkTestnet],
  transports: {
    [mainnet.id]: http(),
    [sepolia.id]: http(),
    [etherlinkTestnet.id]: http(),
  },
});

// Export the providers component
export function Providers({ children }) {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider theme={darkTheme()} wallets={wallets}>
          {children}
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}