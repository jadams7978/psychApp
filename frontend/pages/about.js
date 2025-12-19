import Navbar from "@/components/Navbar";

export default function About() {
  return (
    <>
      <Navbar />
      <main className="max-w-6xl mx-auto p-6">
        <h1 className="text-2xl font-semibold mb-4">About</h1>
        <p className="text-gray-700 dark:text-gray-300">
          An open, modern directory connecting people with mental health professionals.
        </p>
      </main>
    </>
  );
}
