import { Wallet } from "lucide-react";

export default function WalletConnectCard() {
  return (
    <div className="rounded-3xl border border-zinc-800 bg-zinc-900/60 p-6">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-semibold">Wallet State</h3>
        <Wallet size={16} className="text-zinc-400" />
      </div>

      <div className="mt-5 space-y-4 text-sm">
        <div>
          <p className="text-xs uppercase tracking-wide text-zinc-500">Connected Wallet</p>
          <p className="mt-1 text-zinc-300">0x12F4...A91D</p>
        </div>

        <div>
          <p className="text-xs uppercase tracking-wide text-zinc-500">Network</p>
          <p className="mt-1 text-zinc-300">Sepolia</p>
        </div>

        <div>
          <p className="text-xs uppercase tracking-wide text-zinc-500">Token</p>
          <p className="mt-1 text-zinc-300">AUTHD (placeholder)</p>
        </div>
      </div>
    </div>
  );
}