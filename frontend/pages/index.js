import Navbar from "@/components/Navbar";
import Link from "next/link";

export default function Home() {
  return (
    <>
      <Navbar />
      <main className="max-w-6xl mx-auto p-6">
        <h1 className="text-3xl font-bold mb-4">Find a Therapist</h1>
        <p className="mb-6 text-gray-600 dark:text-gray-300">
          Search licensed therapists by specialty, insurance, and availability.
        </p>
        <Link href="/providers" className="inline-block rounded-lg bg-gray-900 text-white dark:bg-white dark:text-gray-900 px-4 py-2">
          Browse Providers
        </Link>
      </main>
    </>
  );
}
