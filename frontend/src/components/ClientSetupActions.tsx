import { useEffect } from 'react';
import { formatEther } from 'viem';
import { sepolia } from 'viem/chains';
import {
  useAccount,
  usePublicClient,
  useReadContracts,
  useWaitForTransactionReceipt,
  useWriteContract,
  useSwitchChain,
} from 'wagmi';
import { customClientAbi } from '../lib/abi/customClientAbi';
import { env } from '../lib/env';

const txLink = (hash?: `0x${string}`) =>
  hash ? `https://sepolia.etherscan.io/tx/${hash}` : undefined;

type Props = {
  onSuccess?: () => void;
};

export const ClientSetupActions = ({ onSuccess }: Props) => {
  const { address, isConnected, chainId } = useAccount();
  const { switchChainAsync } = useSwitchChain();
  const publicClient = usePublicClient();

  const registration = useReadContracts({
    allowFailure: false,
    contracts: [
      {
        address: env.customClientAddress,
        abi: customClientAbi,
        functionName: 'isRegisteredClient',
        // No args — custom client checks msg.sender internally
      },
      {
        address: env.customClientAddress,
        abi: customClientAbi,
        functionName: 'getRegistrationFee',
      },
    ],
    query: {
      staleTime: 10_000,
      enabled: Boolean(address),
    },
  });

  const write = useWriteContract();
  const receipt = useWaitForTransactionReceipt({ hash: write.data });

  const isRegistered = registration.data ? Boolean(registration.data[0]) : false;
  const fee = registration.data ? (registration.data[1] as bigint) : undefined;

  useEffect(() => {
    if (!receipt.isSuccess) return;
    void registration.refetch();
    onSuccess?.();
  }, [onSuccess, receipt.isSuccess, registration]);

  const ensureSepolia = async () => {
    if (chainId !== sepolia.id) {
      await switchChainAsync({ chainId: sepolia.id });
    }
  };

  const registerClient = async () => {
    if (!publicClient) throw new Error('Public client not ready');
    if (!address) throw new Error('Wallet not connected');
    if (fee === undefined) throw new Error('Registration fee not loaded');

    await ensureSepolia();

    const simulation = await publicClient.simulateContract({
      address: env.customClientAddress,
      abi: customClientAbi,
      functionName: 'registerClient',
      value: fee,
      account: address,
    });

    const hash = await write.writeContractAsync(simulation.request);
    console.log('tx hash', hash);
  };

  const mintDemoTokens = async () => {
    if (!publicClient) throw new Error('Public client not ready');
    if (!address) throw new Error('Wallet not connected');

    await ensureSepolia();

    const simulation = await publicClient.simulateContract({
      address: env.customClientAddress,
      abi: customClientAbi,
      functionName: 'buyTokens',
      args: [10n],
      account: address,
    });

    const hash = await write.writeContractAsync(simulation.request);
    console.log('buy tx hash', hash);
  };

  const activeHash = write.data;

  return (
    <div className="setup-panel">
      <div className="setup-copy">
        <span className="setup-label">Client setup</span>
        <strong>{isRegistered ? 'Registered with server' : 'Not registered yet'}</strong>
        <p className="muted">
          First register the client through the client contract, then mint a small demo balance before recording
          authorize flows.
        </p>

        <p className="setup-meta">Wallet: {address ?? 'Not connected'}</p>
        <p className="setup-meta">Chain ID: {chainId ?? 'Unknown'}</p>
        {fee !== undefined ? <p className="setup-meta">Registration fee: {formatEther(fee)} ETH</p> : null}

        {write.error ? <p className="error-text">{write.error.message}</p> : null}

        {activeHash ? (
          <p className="setup-meta">
            Transaction:{' '}
            <a href={txLink(activeHash)} target="_blank" rel="noreferrer">
              {`${activeHash.slice(0, 10)}...${activeHash.slice(-8)}`}
            </a>
          </p>
        ) : null}
      </div>

      <div className="setup-actions">
        <button
          className="secondary-button"
          disabled={!isConnected || isRegistered || write.isPending || registration.isLoading || fee === undefined}
          onClick={() => void registerClient()}
        >
          {write.isPending ? 'Confirm in wallet…' : 'Register client'}
        </button>

        <button
          className="secondary-button"
          disabled={!isConnected || !isRegistered || write.isPending}
          onClick={() => void mintDemoTokens()}
        >
          {write.isPending ? 'Confirm in wallet…' : 'Mint 10 demo tokens'}
        </button>
      </div>
    </div>
  );
};