import SwapInterface from './components/SwapInterface';
import Navbar from './components/Navbar';
import './style.css';

export default function Home() {
  return (
    <div className="min-h-screen bg-gray-900">
      <Navbar />
      
      <main className="container mx-auto py-8 px-4 justify-center">
        <h1 className="text-3xl font-bold text-center text-white mb-8">Swap tokens instantly</h1>
        <SwapInterface />
    
      </main>
    </div>
  );
}
