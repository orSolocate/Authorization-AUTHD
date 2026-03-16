import type { AuthorizationStatus } from "../../types/authorization";

type StatusBadgeProps = {
  status: AuthorizationStatus;
};

export default function StatusBadge({ status }: StatusBadgeProps) {
  return (
    <span className="rounded-full border border-zinc-700 px-3 py-1 text-xs text-zinc-300">
      {status}
    </span>
  );
}