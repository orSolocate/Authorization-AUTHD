import { LogIn } from "lucide-react";

export default function LoginCard() {
  return (
    <div className="rounded-3xl border border-zinc-800 bg-zinc-900/60 p-6">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-semibold">Login State</h3>
        <LogIn size={16} className="text-zinc-400" />
      </div>

      <div className="mt-5 space-y-4 text-sm">
        <div>
          <p className="text-xs uppercase tracking-wide text-zinc-500">User</p>
          <p className="mt-1 text-white">Elhan Iqbal</p>
        </div>

        <div>
          <p className="text-xs uppercase tracking-wide text-zinc-500">Email</p>
          <p className="mt-1 text-zinc-300">elhan@example.com</p>
        </div>

        <div>
          <p className="text-xs uppercase tracking-wide text-zinc-500">Session</p>
          <p className="mt-1 text-zinc-300">Mock authenticated user</p>
        </div>
      </div>
    </div>
  );
}