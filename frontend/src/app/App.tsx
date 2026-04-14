import { useMemo, useState } from 'react';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useAccount } from 'wagmi';
import { ActionModal } from '../components/ActionModal';
import { AuthorizationTable } from '../components/AuthorizationTable';
import { SectionCard } from '../components/SectionCard';
import { ClientSetupActions } from '../components/ClientSetupActions';
import { ViewTabs } from '../components/ViewTabs';
import { useAuthorizations, useFilteredAuthorizations } from '../features/authorizations/useAuthorizations';
import { useTokenMeta } from '../features/authorizations/useTokenMeta';
import { formatTokenAmount, shortAddress } from '../lib/format';
import { DashboardView, AuthorizationRow } from '../types/authorization';

export default function App() {
  const [view, setView] = useState<DashboardView>('grantedByMe');
  const [selectedRow, setSelectedRow] = useState<AuthorizationRow | undefined>();
  const [modalOpen, setModalOpen] = useState(false);
  const { address, isConnected } = useAccount();
  const tokenMeta = useTokenMeta();
  const auths = useAuthorizations();
  const filtered = useFilteredAuthorizations(auths.data, address);

  const rows = useMemo(() => {
    return view === 'grantedByMe' ? filtered.grantedByMe : filtered.grantedToMe;
  }, [filtered.grantedByMe, filtered.grantedToMe, view]);

  const openModal = (row?: AuthorizationRow) => {
    setSelectedRow(row);
    setModalOpen(true);
  };

  return (
    <div className="page-shell">
      <header className="topbar">
        <div>
          <p className="eyebrow">Demo Frontend</p>
          <h1>Authorization-AUTHD</h1>
          <p className="muted">Local Demo For Authorization</p>
        </div>
        <ConnectButton />
      </header>

      <main className="layout-grid">
        <SectionCard
          title={tokenMeta.data?.symbol ?? 'Token'}
          subtitle="Connected token/client overview"
          rightSlot={
            <button className="secondary-button" onClick={() => openModal(undefined)} disabled={!isConnected}>
              New authorization
            </button>
          }
        >
          <div className="stats-grid">
            <div className="stat-item">
              <span className="stat-label">Token name</span>
              <strong>{tokenMeta.data?.name ?? 'Loading...'}</strong>
            </div>
            <div className="stat-item">
              <span className="stat-label">My balance</span>
              <strong>
                {tokenMeta.data
                  ? `${formatTokenAmount(tokenMeta.data.balance, tokenMeta.data.decimals)} ${tokenMeta.data.symbol}`
                  : 'Loading...'}
              </strong>
            </div>
            <div className="stat-item">
              <span className="stat-label">Connected wallet</span>
              <strong>{address ? shortAddress(address) : 'Not connected'}</strong>
            </div>
          </div>

          <ClientSetupActions
            onSuccess={() => {
              void tokenMeta.refetch();
              void auths.refetch();
            }}
          />
        </SectionCard>

        <SectionCard
          title="Authorizations"
          subtitle={
            isConnected
              ? 'Switch between the two views and manage caps directly from the connected wallet.'
              : 'Connect a wallet to interact. Reads still load from Sepolia.'
          }
          rightSlot={<ViewTabs value={view} onChange={setView} />}
        >
          {auths.isLoading || tokenMeta.isLoading ? (
            <p className="muted">Loading on-chain data…</p>
          ) : (
            <AuthorizationTable
              rows={rows}
              symbol={tokenMeta.data?.symbol ?? 'TOKEN'}
              decimals={tokenMeta.data?.decimals ?? 18}
              view={view}
              onAction={openModal}
            />
          )}
        </SectionCard>
      </main>

      <ActionModal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        row={selectedRow}
        decimals={tokenMeta.data?.decimals ?? 18}
        symbol={tokenMeta.data?.symbol ?? 'TOKEN'}
        view={view}
      />
    </div>
  );
}
