import Navbar from "../components/Navbar";
import SendInterface from "../components/SendInterface";
import "../style.css";

export default function Send() {
  return (
    <div className="min-h-screen bg-gray-900">
      <Navbar />
      <main className="container mx-auto py-8 px-4">
        <h1 className="text-3xl font-bold text-center text-white mb-8">
          Send coins
        </h1>
        <SendInterface />
      </main>
    </div>
  );
}
