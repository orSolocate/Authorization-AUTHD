import { formatUnits, parseUnits } from 'viem';

export const shortAddress = (value?: string) => {
  if (!value) return '—';
  return `${value.slice(0, 6)}...${value.slice(-4)}`;
};

export const formatTokenAmount = (amount: bigint, decimals: number, maxFraction = 4) => {
  const raw = Number(formatUnits(amount, decimals));
  if (!Number.isFinite(raw)) return formatUnits(amount, decimals);
  return raw.toLocaleString(undefined, {
    minimumFractionDigits: 0,
    maximumFractionDigits: maxFraction,
  });
};

export const parseTokenInput = (value: string, decimals: number) => {
  const normalized = value.trim();
  if (!normalized) return 0n;
  return parseUnits(normalized, decimals);
};

export const toDateTime = (timestampSeconds?: bigint) => {
  if (!timestampSeconds) return '—';
  const date = new Date(Number(timestampSeconds) * 1000);
  return date.toLocaleString();
};
