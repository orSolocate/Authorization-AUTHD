import { Plus, Search, SlidersHorizontal } from "lucide-react";

export default function DashboardToolbar() {
  return (
    <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
      <div className="flex items-center gap-3 rounded-2xl border border-zinc-800 bg-zinc-950/60 px-4 py-3 text-sm text-zinc-400 md:w-[340px]">
        <Search size={16} />
        <span>Search by wallet, label, or spender</span>
      </div>

      <div className="flex gap-3">
        <button className="inline-flex items-center gap-2 rounded-2xl border border-zinc-700 px-4 py-3 text-sm text-zinc-200 hover:bg-zinc-800">
          <SlidersHorizontal size={16} />
          Filter
        </button>

        <button className="inline-flex items-center gap-2 rounded-2xl bg-white px-4 py-3 text-sm font-semibold text-zinc-900 hover:bg-zinc-200">
          <Plus size={16} />
          New Authorization
        </button>
      </div>
    </div>
  );
}