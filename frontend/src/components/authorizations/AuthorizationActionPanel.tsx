import { Ban, ChevronRight, Plus } from "lucide-react";
import type { DashboardTab } from "../../types/authorization";
import SectionCard from "../dashboard/SectionCard.js";

type AuthorizationActionPanelProps = {
  mode: DashboardTab;
};

export default function AuthorizationActionPanel({
  mode,
}: AuthorizationActionPanelProps) {
  const isOutgoing = mode === "grantedByMe";

  const actions = isOutgoing
    ? [
        {
          title: "Create Authorization",
          desc: "Maps to authorize(owner, authorized, cap).",
        },
        {
          title: "Increase Cap",
          desc: "Maps to increaseAuthorizedCap(owner, authorized, addedCap).",
        },
        {
          title: "Decrease Cap",
          desc: "Maps to decreaseAuthorizedCap(owner, authorized, subtractedCap).",
        },
        {
          title: "Revoke Authorization",
          desc: "Maps to revokeAuthorization(owner, authorized).",
        },
      ]
    : [
        {
          title: "Check Authorization",
          desc: "Maps to isAuthorized(addr, owner, authorized).",
        },
        {
          title: "View Remaining Cap",
          desc: "Maps to getAuthorizedCap(addr, owner, authorized).",
        },
        {
          title: "Approve For Spender",
          desc: "Maps to approveFor(owner, authorized, spender, amount).",
        },
        {
          title: "View Owner Context",
          desc: "Future place for richer owner/delegate metadata.",
        },
      ];

  return (
    <SectionCard
      title={isOutgoing ? "Authorization Actions" : "Delegate Actions"}
      subtitle={
        isOutgoing
          ? "Placeholder UI for owner-side actions."
          : "Placeholder UI for authorized-side actions."
      }
      action={
        <button className="inline-flex items-center gap-2 rounded-2xl border border-zinc-700 px-4 py-2 text-sm text-zinc-200 hover:bg-zinc-800">
          <Plus size={16} />
          Open Form
        </button>
      }
    >
      <div className="grid gap-4 md:grid-cols-2">
        {actions.map((action) => (
          <div
            key={action.title}
            className="rounded-2xl border border-zinc-800 bg-zinc-950/50 p-5"
          >
            <div className="flex items-start justify-between gap-3">
              <div>
                <h3 className="font-semibold text-white">{action.title}</h3>
                <p className="mt-2 text-sm text-zinc-400">{action.desc}</p>
              </div>

              <div className="rounded-2xl border border-zinc-800 p-2 text-zinc-400">
                {action.title.includes("Revoke") ? (
                  <Ban size={16} />
                ) : (
                  <ChevronRight size={16} />
                )}
              </div>
            </div>
          </div>
        ))}
      </div>
    </SectionCard>
  );
}