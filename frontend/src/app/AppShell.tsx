import type { ReactNode } from "react";

type AppShellProps = {
  children: ReactNode;
};

export default function AppShell({ children }: AppShellProps) {
  return <div className="min-h-screen bg-zinc-950 text-zinc-100">{children}</div>;
}