import Link from "next/link";

export default function Navbar() {
  return (
    <header className="w-full border-b border-gray-200 dark:border-gray-800">
      <nav className="max-w-6xl mx-auto flex items-center justify-between p-4">
        <Link href="/" className="text-xl font-semibold">Psych Directory</Link>
        <div className="flex items-center gap-4">
          <Link href="/providers" className="hover:underline">Providers</Link>
          <Link href="/about" className="hover:underline">About</Link>
        </div>
      </nav>
    </header>
  );
}
