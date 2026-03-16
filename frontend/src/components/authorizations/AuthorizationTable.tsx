import StatusBadge from "../common/StatusBadge.js";
import type { AuthorizationRecord, DashboardTab } from "../../types/authorization";

type AuthorizationTableProps = {
  mode: DashboardTab;
  rows: AuthorizationRecord[];
};

export default function AuthorizationTable({
  mode,
  rows,
}: AuthorizationTableProps) {
  const firstHeader = mode === "grantedByMe" ? "Authorized To" : "Authorized By";

  return (
    <div className="overflow-hidden rounded-2xl border border-zinc-800">
      <div className="grid grid-cols-6 gap-4 border-b border-zinc-800 bg-zinc-950/80 px-5 py-4 text-xs font-semibold uppercase tracking-wide text-zinc-500">
        <div>{firstHeader}</div>
        <div>Wallet</div>
        <div>Cap</div>
        <div>Remaining</div>
        <div>Spender</div>
        <div>Status</div>
      </div>

      {rows.map((row) => {
        const primaryLabel =
          mode === "grantedByMe" ? row.authorizedLabel : row.ownerLabel;
        const walletValue = mode === "grantedByMe" ? row.authorized : row.owner;

        return (
          <div
            key={row.id}
            className="grid grid-cols-6 gap-4 border-b border-zinc-800 px-5 py-4 text-sm last:border-b-0"
          >
            <div className="font-medium text-white">{primaryLabel}</div>
            <div className="text-zinc-400">{walletValue}</div>
            <div>{row.cap}</div>
            <div>{row.remaining}</div>
            <div className="text-zinc-400">{row.spenderPreview || "-"}</div>
            <div>
              <StatusBadge status={row.status} />
            </div>
          </div>
        );
      })}
    </div>
  );
}