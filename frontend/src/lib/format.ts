export function formatCount(value: number): string {
  return Intl.NumberFormat("en-US").format(value);
}

export function sumTokenValues(
  rows: Array<{ cap: string; remaining: string }>,
  key: "cap" | "remaining"
): number {
  return rows.reduce((acc, row) => {
    const numeric = Number(row[key].split(" ")[0].replace(/,/g, ""));
    return acc + numeric;
  }, 0);
}