import type { DashboardTab } from "../../types/authorization";

type DashboardTabsProps = {
  activeTab: DashboardTab;
  onTabChange: (tab: DashboardTab) => void;
};

export default function DashboardTabs({
  activeTab,
  onTabChange,
}: DashboardTabsProps) {
  const tabClass = (selected: boolean) =>
    selected
      ? "rounded-2xl bg-white px-4 py-2 text-sm font-semibold text-zinc-900"
      : "rounded-2xl border border-zinc-700 px-4 py-2 text-sm text-zinc-200 hover:bg-zinc-800";

  return (
    <div className="flex flex-wrap gap-3">
      <button
        className={tabClass(activeTab === "grantedByMe")}
        onClick={() => onTabChange("grantedByMe")}
      >
        Granted By Me
      </button>

      <button
        className={tabClass(activeTab === "grantedToMe")}
        onClick={() => onTabChange("grantedToMe")}
      >
        Granted To Me
      </button>
    </div>
  );
}