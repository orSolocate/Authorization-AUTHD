# ERC20 Authorized Frontend (updated package stack)

This version is rebuilt around current wallet/frontend docs instead of older MetaMask SDK packages.

## Why this stack

This repo uses:

- `wagmi`
- `viem`
- `@tanstack/react-query`
- `@rainbow-me/rainbowkit`
- `vite`

That matches the current official Wagmi + RainbowKit setup pattern for React apps, and avoids deprecated MetaMask SDK React packages.

## Docs used

- Wagmi Getting Started: install `wagmi`, `viem`, and `@tanstack/react-query`
- Wagmi Connect Wallet: configure connectors and providers
- RainbowKit Installation: use `getDefaultConfig`, `WagmiProvider`, `QueryClientProvider`, and `RainbowKitProvider`
- MetaMask developer release notes: several MetaMask SDK packages are marked deprecated, so this repo does **not** use them

## Quick start

```bash
npm install
cp .env.example .env
npm run dev
```

## .env

```env
VITE_WALLETCONNECT_PROJECT_ID=your_reown_project_id
VITE_SEPOLIA_RPC_URL=https://ethereum-sepolia-rpc.publicnode.com
VITE_CUSTOM_CLIENT_ADDRESS=0x610D238A77821229ABAE94Df738DA97811EA014A
VITE_SERVER_ADDRESS=0xFEB91Ced20B008F6F5BEBC9189EC7837894584A1
```

## Important note about ABI assumptions

I kept the ABI intentionally small and readable.

This frontend assumes the CustomClient exposes these methods:

- `authorize(address,uint256)`
- `increaseAuthorizedCap(address,uint256)`
- `decreaseAuthorizedCap(address,uint256)`
- `revokeAuthorization(address)`
- `approveFor(address,address,uint256)`

It also reconstructs dashboard rows from server events:

- `Authorization`
- `IncreaseAuthorizedCap`
- `DecreaseAuthorizedCap`
- `RevokeAuthorization`
- `ApproveFor`

If your verified contract uses slightly different names/signatures, only update these files:

- `src/lib/abi/customClientAbi.ts`
- `src/lib/abi/serverEventsAbi.ts`

## Repo structure

```text
src/
├─ app/App.tsx
├─ components/
│  ├─ ActionModal.tsx
│  ├─ AuthorizationTable.tsx
│  ├─ SectionCard.tsx
│  └─ ViewTabs.tsx
├─ features/authorizations/
│  ├─ useAuthorizations.ts
│  └─ useTokenMeta.ts
├─ lib/
│  ├─ abi/
│  │  ├─ customClientAbi.ts
│  │  └─ serverEventsAbi.ts
│  ├─ chain.ts
│  ├─ env.ts
│  ├─ format.ts
│  └─ wagmi.ts
├─ styles/global.css
├─ types/authorization.ts
└─ main.tsx
```

## Demo flow for your video

1. Start on Sepolia in MetaMask or Rabby.
2. Connect wallet.
3. Show token metadata and balance.
4. Switch between `Granted By Me` and `Granted To Me`.
5. Create a new authorization.
6. Manage one row with increase/decrease/revoke, or `approveFor` from the delegated side.

## Simplifications made on purpose

- minimal styling
- no backend required
- no generated ABI tooling
- no deprecated MetaMask SDK packages
- event-derived dashboard rows for faster demo setup
