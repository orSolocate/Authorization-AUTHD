import SectionCard from "../dashboard/SectionCard.js";
import PreviewField from "../common/PreviewField.js";
import type { AuthorizationRecord, DashboardTab } from "../../types/authorization";

type ClientIntegrationPreviewProps = {
  mode: DashboardTab;
  rows: AuthorizationRecord[];
};

export default function ClientIntegrationPreview({
  mode,
  rows,
}: ClientIntegrationPreviewProps) {
  const preview = rows[0];

  return (
    <SectionCard
      title="Client / Token Integration Mock"
      subtitle="Placeholder detail card for unfinished client and custom token integration."
    >
      <div className="space-y-4">
        <div className="rounded-2xl border border-zinc-800 bg-zinc-950/60 p-5">
          <p className="text-xs uppercase tracking-wide text-zinc-500">
            Selected Relationship
          </p>

          <div className="mt-4 grid gap-4 sm:grid-cols-2">
            <PreviewField label="Owner" value={preview.ownerLabel} />
            <PreviewField label="Owner Wallet" value={preview.owner} />
            <PreviewField label="Authorized" value={preview.authorizedLabel} />
            <PreviewField label="Authorized Wallet" value={preview.authorized} />
            <PreviewField label="Current Cap" value={preview.cap} />
            <PreviewField label="Remaining" value={preview.remaining} />
            <PreviewField label="Suggested Spender" value={preview.spenderPreview || "-"} />
            <PreviewField label="Last Updated" value={preview.lastUpdated} />
          </div>
        </div>

        <div className="rounded-2xl border border-dashed border-zinc-700 bg-zinc-950/30 p-5">
          <p className="text-sm font-medium text-white">Future wiring points</p>

          <div className="mt-3 space-y-2 text-sm text-zinc-400">
            <p>• Replace mock rows with contract reads or server responses.</p>
            <p>• Add optimistic UI for authorize, increase, decrease, and revoke.</p>
            <p>• Add token approval history once approveFor is finalized.</p>
            <p>
              • {mode === "grantedByMe"
                ? "Show revoke and cap edit modal here."
                : "Show approveFor modal here."}
            </p>
          </div>
        </div>
      </div>
    </SectionCard>
  );
}