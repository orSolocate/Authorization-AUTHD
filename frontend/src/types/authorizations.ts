export type DashboardTab = "grantedByMe" | "grantedToMe";

export type AuthorizationStatus = "Active" | "Revoked" | "Partially Used";

export type AuthorizationRecord = {
  id: string;
  owner: string;
  ownerLabel: string;
  authorized: string;
  authorizedLabel: string;
  cap: string;
  remaining: string;
  status: AuthorizationStatus;
  spenderPreview?: string;
  lastUpdated: string;
};