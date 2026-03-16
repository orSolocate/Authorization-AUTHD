import type { LucideIcon } from "lucide-react";

type SummaryCardProps = {
  label: string;
  value: string;
  hint: string;
  icon: LucideIcon;
};

export default function SummaryCard({
  label,
  value,
  hint,
  icon: Icon,
}: SummaryCardProps) {
  return (
    <div className="rounded-2xl border border-zinc-800 bg-zinc-950/70 p-5">
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="text-sm text-zinc-400">{label}</p>
          <p className="mt-2 text-2xl font-semibold text-white">{value}</p>
          <p className="mt-1 text-xs text-zinc-500">{hint}</p>
        </div>
        <div className="rounded-2xl border border-zinc-800 p-2 text-zinc-300">
          <Icon size={18} />
        </div>
      </div>
    </div>
  );
}