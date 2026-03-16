import { LogIn, Wallet } from "lucide-react";

export default function HeaderBar() {
  return (
    <header className="mb-8 flex flex-col gap-4 rounded-3xl border border-zinc-800 bg-zinc-900/60 p-6 lg:flex-row lg:items-center lg:justify-between">
      <div>
        <p className="text-sm uppercase tracking-[0.25em] text-zinc-500">
          ERC20Authorized dApp
        </p>
        <h1 className="mt-2 text-3xl font-semibold">Frontend Scaffold</h1>
        <p className="mt-2 max-w-3xl text-sm text-zinc-400">
          Built around authorize, cap lookup, increase/decrease cap, revoke, and approveFor.
        </p>
      </div>

      <div className="flex items-center gap-3">
        <button className="inline-flex items-center gap-2 rounded-2xl border border-zinc-700 px-4 py-3 text-sm font-medium text-zinc-200 hover:bg-zinc-800">
          <LogIn size={16} />
          Sign In
        </button>

        <button className="inline-flex items-center gap-2 rounded-2xl bg-white px-4 py-3 text-sm font-semibold text-zinc-900 hover:bg-zinc-200">
          <Wallet size={16} />
          Connect Wallet
        </button>
      </div>
    </header>
  );
}