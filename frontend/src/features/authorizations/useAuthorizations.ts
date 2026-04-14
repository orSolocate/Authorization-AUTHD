import { useMemo } from 'react';
import { usePublicClient } from 'wagmi';
import { useQuery } from '@tanstack/react-query';
import { decodeEventLog } from 'viem';
import { env } from '../../lib/env';
import { serverEventsAbi } from '../../lib/abi/serverEventsAbi';
import { AuthorizationRow } from '../../types/authorization';

const zeroAddress = '0x0000000000000000000000000000000000000000' as const;

const CONTRACT_DEPLOY_BLOCK = 10607922n;

// Actual on-chain topic hashes — verified from Sepolia logs
const TOPICS = {
  Authorization:        '0xede87e9876630140ad0c9c48ac9eb24f60bc571910e448bfbe9b42581f4b4a0d',
  IncreaseAuthorizedCap:'0x8a2d27439e1d41db8aa6a37498dcc08f5d8e6742f25c421d8d01df97ded710f7',
  DecreaseAuthorizedCap:'0x8a2d27439e1d41db8aa6a37498dcc08f5d8e6742f25c421d8d01df97ded710f7', // update if different
  RevokeAuthorization:  '0xa9dd68d2c9a78fd8847645b763094e99e4c98c4531260cb7265f1047a33c03a0',
  ApproveFor:           '0x3289f8ec269907255ca90ef0f9b49b9cde8cd0562753991aa4aa48bc4506e05a',
} as const;

type StateMap = Map<string, AuthorizationRow>;
const makeKey = (owner: string, authorized: string) =>
  `${owner.toLowerCase()}-${authorized.toLowerCase()}`;

export const useAuthorizations = () => {
  const publicClient = usePublicClient();

  return useQuery({
    queryKey: ['authorizations', env.serverAddress, env.customClientAddress],
    enabled: Boolean(publicClient),
    queryFn: async () => {
      if (!publicClient) return [] as AuthorizationRow[];

      const fromBlock = CONTRACT_DEPLOY_BLOCK;
      const toBlock = 'latest' as const;

      // Fetch all logs from the server contract in one call, then split by topic
      const allLogs = await publicClient.getLogs({
        address: env.serverAddress,
        fromBlock,
        toBlock,
      });

      console.log('total logs fetched:', allLogs.length);

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

      for (const log of allLogs) {
        const topic0 = log.topics[0];
        if (!topic0) continue;

        try {
          if (topic0 === TOPICS.Authorization) {
            const decoded = decodeEventLog({
              abi: serverEventsAbi,
              eventName: 'Authorization',
              topics: log.topics,
              data: log.data,
              strict: false,
            });
            const { client, owner, authorized, cap } = decoded.args as {
              client: `0x${string}`;
              owner: `0x${string}`;
              authorized: `0x${string}`;
              cap: bigint;
            };
            if (!client || !owner || !authorized) continue;
            if (client.toLowerCase() !== env.customClientAddress.toLowerCase()) continue;
            const row = upsert(owner, authorized, client);
            row.cap = cap ?? 0n;
            row.lastEventBlock = log.blockNumber;
            row.lastEventName = 'Authorization';

          } else if (topic0 === TOPICS.IncreaseAuthorizedCap) {
            const decoded = decodeEventLog({
              abi: serverEventsAbi,
              eventName: 'IncreaseAuthorizedCap',
              topics: log.topics,
              data: log.data,
              strict: false,
            });
            const { client, owner, authorized, newCap } = decoded.args as {
              client: `0x${string}`;
              owner: `0x${string}`;
              authorized: `0x${string}`;
              newCap: bigint;
            };
            if (!client || !owner || !authorized) continue;
            if (client.toLowerCase() !== env.customClientAddress.toLowerCase()) continue;
            const row = upsert(owner, authorized, client);
            row.cap = newCap ?? 0n;
            row.lastEventBlock = log.blockNumber;
            row.lastEventName = 'IncreaseAuthorizedCap';

          } else if (topic0 === TOPICS.DecreaseAuthorizedCap) {
            const decoded = decodeEventLog({
              abi: serverEventsAbi,
              eventName: 'DecreaseAuthorizedCap',
              topics: log.topics,
              data: log.data,
              strict: false,
            });
            const { client, owner, authorized, newCap } = decoded.args as {
              client: `0x${string}`;
              owner: `0x${string}`;
              authorized: `0x${string}`;
              newCap: bigint;
            };
            if (!client || !owner || !authorized) continue;
            if (client.toLowerCase() !== env.customClientAddress.toLowerCase()) continue;
            const row = upsert(owner, authorized, client);
            row.cap = newCap ?? 0n;
            row.lastEventBlock = log.blockNumber;
            row.lastEventName = 'DecreaseAuthorizedCap';

          } else if (topic0 === TOPICS.RevokeAuthorization) {
            const decoded = decodeEventLog({
              abi: serverEventsAbi,
              eventName: 'RevokeAuthorization',
              topics: log.topics,
              data: log.data,
              strict: false,
            });
            const { client, owner, authorized } = decoded.args as {
              client: `0x${string}`;
              owner: `0x${string}`;
              authorized: `0x${string}`;
            };
            if (!client || !owner || !authorized) continue;
            if (client.toLowerCase() !== env.customClientAddress.toLowerCase()) continue;
            state.delete(makeKey(owner, authorized));

          } else if (topic0 === TOPICS.ApproveFor) {
            const decoded = decodeEventLog({
              abi: serverEventsAbi,
              eventName: 'ApproveFor',
              topics: log.topics,
              data: log.data,
              strict: false,
            });
            const { client, owner, authorized, approvedAmount } = decoded.args as {
              client: `0x${string}`;
              owner: `0x${string}`;
              authorized: `0x${string}`;
              approvedAmount: bigint;
            };
            if (!client || !owner || !authorized) continue;
            if (client.toLowerCase() !== env.customClientAddress.toLowerCase()) continue;
            const row = upsert(owner, authorized, client);
            row.totalApproved += approvedAmount ?? 0n;
            row.lastEventBlock = log.blockNumber;
            row.lastEventName = 'ApproveFor';
          }
        } catch (e) {
          // Skip logs that can't be decoded
          continue;
        }
      }

      return [...state.values()]
        .filter((row) => row.owner !== zeroAddress && row.authorized !== zeroAddress && row.cap >= 0n)
        .sort((a, b) => Number((b.lastEventBlock ?? 0n) - (a.lastEventBlock ?? 0n)));
    },
    staleTime: 60_000,
    refetchInterval: false,
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