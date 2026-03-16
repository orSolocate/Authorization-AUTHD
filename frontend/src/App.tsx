import { useMemo, useState } from "react";
import { ArrowDownLeft, ArrowUpRight, LayoutGrid, ShieldCheck } from "lucide-react";

import AppShell from "./app/AppShell";
import HeaderBar from "./components/layout/HeaderBar";
import Sidebar from "./components/layout/Sidebar";
import SectionCard from "./components/dashboard/SectionCard";
import SummaryCard from "./components/dashboard/SummaryCard";
import DashboardTabs from "./components/dashboard/DashboardTabs";
import DashboardToolbar from "./components/dashboard/DashboardToolbar";
import AuthorizationTable from "./components/authorizations/AuthorizationTable";
import AuthorizationActionPanel from "./components/authorizations/AuthorizationActionPanel";
import ClientIntegrationPreview from "./components/authorizations/ClientIntegrationPreview";

import { MOCK_GRANTED_BY_ME, MOCK_GRANTED_TO_ME } from "./data/mockAuthorizations";
import { formatCount, sumTokenValues } from "./lib/format";
import type { DashboardTab } from "./types/authorization";

export default function App() {
  const [activeTab, setActiveTab] = useState<DashboardTab>("grantedByMe");

  const rows = activeTab === "grantedByMe" ? MOCK_GRANTED_BY_ME : MOCK_GRANTED_TO_ME;

  const totalCap = sumTokenValues(rows, "cap");
  const totalRemaining = sumTokenValues(rows, "remaining");
  const activeCount = rows.filter((r) => r.status === "Active").length;

  const title = activeTab === "grantedByMe" ? "Granted By Me" : "Granted To Me";
  const subtitle =
    activeTab === "grantedByMe"
      ? "Shows delegates you authorized and how much cap remains for each one."
      : "Shows accounts that authorized you and what you can still use.";

  const currentSubtitle = useMemo(
    () =>
      activeTab === "grantedByMe"
        ? "Owner-centric view for managing delegates, caps, and revocations."
        : "Delegate-centric view for seeing who authorized you and what you can use.",
    [activeTab]
  );

  return (
    <AppShell>
      <div className="mx-auto max-w-7xl px-6 py-8">
        <HeaderBar />

        <div className="mb-6 rounded-2xl border border-zinc-800 bg-zinc-900/50 px-5 py-4 text-sm text-zinc-400">
          Active view: <span className="font-medium text-zinc-200">{currentSubtitle}</span>
        </div>

        <div className="grid gap-8 lg:grid-cols-[320px_minmax(0,1fr)]">
          <Sidebar activeTab={activeTab} onTabChange={setActiveTab} />

          <main className="space-y-8">
            <SectionCard
              title={title}
              subtitle={subtitle}
              action={
                <DashboardTabs activeTab={activeTab} onTabChange={setActiveTab} />
              }
            >
              <DashboardToolbar />

              <div className="mt-6 grid gap-4 md:grid-cols-3">
                <SummaryCard
                  label={activeTab === "grantedByMe" ? "Total Authorized" : "Total Received"}
                  value={`${formatCount(totalCap)} AUTHD`}
                  hint="Mock aggregated value from current table"
                  icon={LayoutGrid}
                />

                <SummaryCard
                  label="Remaining Amount"
                  value={`${formatCount(totalRemaining)} AUTHD`}
                  hint="This would later come from contract reads"
                  icon={ShieldCheck}
                />

                <SummaryCard
                  label={activeTab === "grantedByMe" ? "Active Delegates" : "Active Authorizers"}
                  value={String(activeCount)}
                  hint="Distinct active relationships"
                  icon={activeTab === "grantedByMe" ? ArrowUpRight : ArrowDownLeft}
                />
              </div>

              <div className="mt-8">
                <AuthorizationTable mode={activeTab} rows={rows} />
              </div>
            </SectionCard>

            <div className="grid gap-8 xl:grid-cols-[1.15fr_0.85fr]">
              <AuthorizationActionPanel mode={activeTab} />
              <ClientIntegrationPreview mode={activeTab} rows={rows} />
            </div>
          </main>
        </div>
      </div>
    </AppShell>
  );
}