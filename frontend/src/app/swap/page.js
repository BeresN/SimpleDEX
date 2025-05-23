import Navbar from "../components/Navbar";
import SwapInterface from "../components/SwapInterface";
import "../style.css";

export default function Swap() {
  return (
    <div className="min-h-screen bg-gray-900">
      <Navbar />
      <main className="container mx-auto py-8 px-4">
        <h1 className="text-3xl font-bold text-center text-white mb-8">
          Swap tokens
        </h1>
        <SwapInterface />
      </main>
    </div>
  );
}
