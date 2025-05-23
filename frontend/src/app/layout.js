import "./globals.css";
import { Providers } from "./providers";

export const metadata = {
  title: "My DEX",
  description: "A decentralized exchange like Uniswap",
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
