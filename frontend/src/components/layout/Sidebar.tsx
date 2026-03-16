import LoginCard from "../auth/LoginCard.js";
import WalletConnectCard from "../wallet/WalletConnectCard.js";
import type { DashboardTab } from "../../types/authorization";

type SidebarProps = {
  activeTab: DashboardTab;
  onTabChange: (tab: DashboardTab) => void;
};

function NavigationCard({ activeTab, onTabChange }: SidebarProps) {
  const buttonClass = (selected: boolean) =>
    selected
      ? "w-full rounded-2xl bg-white px-4 py-3 text-left text-sm font-semibold text-zinc-900"
      : "w-full rounded-2xl border border-zinc-700 px-4 py-3 text-left text-sm text-zinc-200 hover:bg-zinc-800";

  return (
    <div className="rounded-3xl border border-zinc-800 bg-zinc-900/60 p-6">
      <h3 className="text-lg font-semibold">Dashboards</h3>

      <div className="mt-4 space-y-3">
        <button
          className={buttonClass(activeTab === "grantedByMe")}
          onClick={() => onTabChange("grantedByMe")}
        >
          Granted By Me
        </button>

        <button
          className={buttonClass(activeTab === "grantedToMe")}
          onClick={() => onTabChange("grantedToMe")}
        >
          Granted To Me
        </button>
      </div>
    </div>
  );
}

function ContractFeaturePreview() {
  const features = [
    "authorize(owner, authorized, cap)",
    "getAuthorizedCap(addr, owner, authorized)",
    "increaseAuthorizedCap(owner, authorized, addedCap)",
    "decreaseAuthorizedCap(owner, authorized, subtractedCap)",
    "isAuthorized(addr, owner, authorized)",
    "revokeAuthorization(owner, authorized)",
    "approveFor(owner, authorized, spender, amount)",
  ];

  return (
    <div className="rounded-3xl border border-dashed border-zinc-700 bg-zinc-900/40 p-6">
      <h3 className="text-lg font-semibold">Contract Integration Preview</h3>
      <p className="mt-2 text-sm text-zinc-400">
        These UI actions map directly to your Solidity interface.
      </p>

      <div className="mt-4 space-y-3">
        {features.map((feature) => (
          <div
            key={feature}
            className="rounded-2xl border border-zinc-800 px-4 py-3 text-sm text-zinc-300"
          >
            {feature}
          </div>
        ))}
      </div>
    </div>
  );
}

export default function Sidebar({ activeTab, onTabChange }: SidebarProps) {
  return (
    <aside className="space-y-6">
      <LoginCard />
      <WalletConnectCard />
      <NavigationCard activeTab={activeTab} onTabChange={onTabChange} />
      <ContractFeaturePreview />
    </aside>
  );
}