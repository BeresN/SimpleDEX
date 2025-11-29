import "./globals.css";
import { Providers } from "./providers";

export const metadata = {
  title: "SimpleDEX",
  description: "A simple decentralized exchange",
};

export default function RootLayout({ children }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body suppressHydrationWarning>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
