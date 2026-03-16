type PreviewFieldProps = {
  label: string;
  value: string;
};

export default function PreviewField({ label, value }: PreviewFieldProps) {
  return (
    <div>
      <p className="text-xs uppercase tracking-wide text-zinc-500">{label}</p>
      <p className="mt-1 text-sm text-zinc-200">{value}</p>
    </div>
  );
}