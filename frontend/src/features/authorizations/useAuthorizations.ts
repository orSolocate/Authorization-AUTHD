import { useMemo } from 'react';
import { usePublicClient } from 'wagmi';
import { useQuery } from '@tanstack/react-query';
import { env } from '../../lib/env';
import { serverEventsAbi } from '../../lib/abi/serverEventsAbi';
import { AuthorizationRow } from '../../types/authorization';

const zeroAddress = '0x0000000000000000000000000000000000000000' as const;

type StateMap = Map<string, AuthorizationRow>;

const makeKey = (owner: string, authorized: string) => `${owner.toLowerCase()}-${authorized.toLowerCase()}`;

export const useAuthorizations = () => {
  const publicClient = usePublicClient();

  return useQuery({
    queryKey: ['authorizations', env.serverAddress, env.customClientAddress],
    enabled: Boolean(publicClient),
    queryFn: async () => {
      if (!publicClient) return [] as AuthorizationRow[];

      const fromBlock = 0n;
      const toBlock = 'latest';

      const [authorizations, increases, decreases, revokes, approves] = await Promise.all([
        publicClient.getLogs({
          address: env.serverAddress,
          abi: serverEventsAbi,
          eventName: 'Authorization',
          fromBlock,
          toBlock,
        }),
        publicClient.getLogs({
          address: env.serverAddress,
          abi: serverEventsAbi,
          eventName: 'IncreaseAuthorizedCap',
          fromBlock,
          toBlock,
        }),
        publicClient.getLogs({
          address: env.serverAddress,
          abi: serverEventsAbi,
          eventName: 'DecreaseAuthorizedCap',
          fromBlock,
          toBlock,
        }),
        publicClient.getLogs({
          address: env.serverAddress,
          abi: serverEventsAbi,
          eventName: 'RevokeAuthorization',
          fromBlock,
          toBlock,
        }),
        publicClient.getLogs({
          address: env.serverAddress,
          abi: serverEventsAbi,
          eventName: 'ApproveFor',
          fromBlock,
          toBlock,
        }),
      ]);

      const state: StateMap = new Map();

      const upsert = (owner: `0x${string}`, authorized: `0x${string}`, client: `0x${string}`) => {
        const key = makeKey(owner, authorized);
        const existing = state.get(key);
        if (existing) return existing;
        const row: AuthorizationRow = {
          key,
          owner,
          authorized,
          client,
          cap: 0n,
          totalApproved: 0n,
        };
        state.set(key, row);
        return row;
      };

      for (const log of authorizations) {
        const args = log.args;
        if (!args.client || !args.owner || !args.authorized) continue;
        if (args.client.toLowerCase() !== env.customClientAddress.toLowerCase()) continue;
        const row = upsert(args.owner, args.authorized, args.client);
        row.cap = args.amount ?? 0n;
        row.lastEventBlock = log.blockNumber;
        row.lastEventName = 'Authorization';
      }

      for (const log of increases) {
        const args = log.args;
        if (!args.client || !args.owner || !args.authorized) continue;
        if (args.client.toLowerCase() !== env.customClientAddress.toLowerCase()) continue;
        const row = upsert(args.owner, args.authorized, args.client);
        row.cap += args.amount ?? 0n;
        row.lastEventBlock = log.blockNumber;
        row.lastEventName = 'IncreaseAuthorizedCap';
      }

      for (const log of decreases) {
        const args = log.args;
        if (!args.client || !args.owner || !args.authorized) continue;
        if (args.client.toLowerCase() !== env.customClientAddress.toLowerCase()) continue;
        const row = upsert(args.owner, args.authorized, args.client);
        row.cap = row.cap > (args.amount ?? 0n) ? row.cap - (args.amount ?? 0n) : 0n;
        row.lastEventBlock = log.blockNumber;
        row.lastEventName = 'DecreaseAuthorizedCap';
      }

      for (const log of revokes) {
        const args = log.args;
        if (!args.client || !args.owner || !args.authorized) continue;
        if (args.client.toLowerCase() !== env.customClientAddress.toLowerCase()) continue;
        const key = makeKey(args.owner, args.authorized);
        state.delete(key);
      }

      for (const log of approves) {
        const args = log.args;
        if (!args.client || !args.owner || !args.authorized) continue;
        if (args.client.toLowerCase() !== env.customClientAddress.toLowerCase()) continue;
        const row = upsert(args.owner, args.authorized, args.client);
        row.totalApproved += args.amount ?? 0n;
        row.lastEventBlock = log.blockNumber;
        row.lastEventName = 'ApproveFor';
      }

      return [...state.values()]
        .filter((row) => row.owner !== zeroAddress && row.authorized !== zeroAddress && row.cap >= 0n)
        .sort((a, b) => Number((b.lastEventBlock ?? 0n) - (a.lastEventBlock ?? 0n)));
    },
    staleTime: 15_000,
    refetchInterval: 20_000,
  });
};

export const useFilteredAuthorizations = (
  rows: AuthorizationRow[] | undefined,
  currentAddress?: `0x${string}`,
) => {
  return useMemo(() => {
    const safeRows = rows ?? [];
    if (!currentAddress) {
      return {
        grantedByMe: safeRows,
        grantedToMe: safeRows,
      };
    }

    const me = currentAddress.toLowerCase();

    return {
      grantedByMe: safeRows.filter((row) => row.owner.toLowerCase() === me),
      grantedToMe: safeRows.filter((row) => row.authorized.toLowerCase() === me),
    };
  }, [rows, currentAddress]);
};
