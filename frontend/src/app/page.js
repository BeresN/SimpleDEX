import Navbar from './components/Navbar';

import './style.css';
import "tailwindcss";

export default function Home() {
  return (
    <div className="min-h-screen bg-gray-900">
      <Navbar />
      
      <main className="container mx-auto py-8 px-4 justify-center">
        <h1 className="text-3xl font-bold text-center text-white mb-8">Homepage</h1>
    
      </main>
    </div>
  );
}
