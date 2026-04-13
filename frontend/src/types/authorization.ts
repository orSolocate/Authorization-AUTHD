export type AuthorizationRow = {
  key: string;
  client: `0x${string}`;
  owner: `0x${string}`;
  authorized: `0x${string}`;
  cap: bigint;
  totalApproved: bigint;
  lastEventBlock?: bigint;
  lastEventName?: string;
};

export type DashboardView = 'grantedByMe' | 'grantedToMe';

export type ActionKind =
  | 'authorize'
  | 'increaseAuthorizedCap'
  | 'decreaseAuthorizedCap'
  | 'revokeAuthorization'
  | 'approveFor';
