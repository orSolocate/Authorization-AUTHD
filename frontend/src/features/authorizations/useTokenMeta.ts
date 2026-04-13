import { useAccount, useReadContracts } from 'wagmi';
import { customClientAbi } from '../../lib/abi/customClientAbi';
import { env } from '../../lib/env';

export type TokenMeta = {
  name: string;
  symbol: string;
  decimals: number;
  balance: bigint;
};

export const useTokenMeta = () => {
  const { address } = useAccount();

  const result = useReadContracts({
    allowFailure: false,
    contracts: [
      {
        address: env.customClientAddress,
        abi: customClientAbi,
        functionName: 'name',
      },
      {
        address: env.customClientAddress,
        abi: customClientAbi,
        functionName: 'symbol',
      },
      {
        address: env.customClientAddress,
        abi: customClientAbi,
        functionName: 'decimals',
      },
      {
        address: env.customClientAddress,
        abi: customClientAbi,
        functionName: 'balanceOf',
        args: [address ?? '0x0000000000000000000000000000000000000000'],
      },
    ],
    query: {
      enabled: true,
      staleTime: 15_000,
    },
  });

  const data = result.data
    ? {
        name: result.data[0] as string,
        symbol: result.data[1] as string,
        decimals: Number(result.data[2]),
        balance: result.data[3] as bigint,
      }
    : undefined;

  return {
    ...result,
    data: data as TokenMeta | undefined,
  };
};
