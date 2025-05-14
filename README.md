# SimpleSwap

A simple decentralized exchange (DEX) and liquidity pool application built with Next.js, React, Wagmi, and Tailwind CSS on the Sepolia testnet. This dApp allows users to connect their wallet, add and remove liquidity for specific ERC-20 token pairs, and perform basic swaps.

## Tech Stack

- **Framework:** Next.js (React)
- **UI:** Tailwind CSS
- **Blockchain Interaction:** Wagmi (React Hooks for Ethereum)
- **Wallet Connection:** RainbowKit
- **Ethereum Utilities:** Viem
- **Smart Contracts:** Solidity (Developed separately)
- **Testing (Smart Contracts):** Foundry
- **OpenZeppelin:** For secure and standard smart contract components (ERC20, ReentrancyGuard).
- **Network:** Sepolia Testnet

## Prerequisites

Before running this project, you need to have:

- Node.js (v18 or higher recommended)
- npm or yarn or pnpm
- Git
- A web browser with an Ethereum wallet extension (like MetaMask) installed and connected to the **Sepolia Testnet**.
- Sepolia ETH and the test ERC-20 tokens (mETH and mSEI) on your connected wallet address.

## Getting Started

1.  **Clone the repository:**

    ```bash
    git clone git@github.com:BeresN/SimpleDEX.git
    cd frontend
    ```

2.  **Install dependencies:**

    ```bash
    npm install
    # or
    yarn install
    # or
    pnpm install
    ```

3.  **Run the development server:**

    ```bash
    npm run dev
    # or
    yarn dev
    # or
    pnpm dev
    ```

4.  Open [http://localhost:3000](http://localhost:3000) in your browser.

5.  Connect your wallet and switch to the **Sepolia Testnet**.

6.  Ensure you have test tokens (Sepolia ETH, mETH and mSEI) in your wallet on Sepolia. If not, you'll need to find a faucet or a way to mint/acquire these specific test tokens.

7.  Mint Tokens for your wallet, ensure that you have some Sepolia ETH tokens. Here is link to faucet [Google Faucet](https://cloud.google.com/application/web3/faucet/ethereum/sepolia)

8.  mETH and mSEI faucets:
    [mETH](https://sepolia.etherscan.io/address/0x558f6e1BFfD83AD9F016865bF98D6763566d49c6#code)
    [mSEI](https://sepolia.etherscan.io/address/0x4DF4493209006683e678983E1Ec097680AB45e13#code)

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
