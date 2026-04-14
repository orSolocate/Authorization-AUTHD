import { useEffect, useMemo, useState } from 'react';
import { useAccount, useWriteContract } from 'wagmi';
import { AuthorizationRow, ActionKind, DashboardView } from '../types/authorization';
import { customClientAbi } from '../lib/abi/customClientAbi';
import { env } from '../lib/env';
import { parseTokenInput, shortAddress } from '../lib/format';

type Props = {
  open: boolean;
  onClose: () => void;
  row?: AuthorizationRow;
  decimals: number;
  symbol: string;
  view: DashboardView;
};

const labels: Record<ActionKind, string> = {
  authorize: 'Authorize',
  increaseAuthorizedCap: 'Increase cap',
  decreaseAuthorizedCap: 'Decrease cap',
  revokeAuthorization: 'Revoke',
  approveFor: 'Approve for',
};

export const ActionModal = ({ open, onClose, row, decimals, symbol, view }: Props) => {
  const [action, setAction] = useState<ActionKind>('authorize');
  const [authorizedAddress, setAuthorizedAddress] = useState('');
  const [spender, setSpender] = useState('');
  const [amount, setAmount] = useState('');

  // Reset state whenever modal opens, row changes, or view changes
  useEffect(() => {
    if (open) {
      if (!row) {
        setAction('authorize');
      } else if (view === 'grantedToMe') {
        setAction('approveFor');
      } else {
        setAction('increaseAuthorizedCap');
      }
      setAuthorizedAddress(row?.authorized ?? '');
      setSpender('');
      setAmount('');
    }
  }, [open, row, view]);

  const { address } = useAccount();
  const write = useWriteContract();

  const availableActions = useMemo<ActionKind[]>(() => {
    if (!row) return ['authorize'];
    if (view === 'grantedByMe') {
      return ['increaseAuthorizedCap', 'decreaseAuthorizedCap', 'revokeAuthorization'];
    }
    return ['approveFor'];
  }, [row, view]);

  const submit = async () => {
    if (!address) throw new Error('Wallet not connected');

    const parsedAmount = amount ? parseTokenInput(amount, decimals) : 0n;

    if (action === 'authorize') {
      await write.writeContractAsync({
        address: env.customClientAddress,
        abi: customClientAbi,
        functionName: 'authorize',
        args: [authorizedAddress as `0x${string}`, parsedAmount],
      });
    } else if (action === 'increaseAuthorizedCap' && row) {
      await write.writeContractAsync({
        address: env.customClientAddress,
        abi: customClientAbi,
        functionName: 'increaseAuthorizedCap',
        args: [row.authorized, parsedAmount],
      });
    } else if (action === 'decreaseAuthorizedCap' && row) {
      await write.writeContractAsync({
        address: env.customClientAddress,
        abi: customClientAbi,
        functionName: 'decreaseAuthorizedCap',
        args: [row.authorized, parsedAmount],
      });
    } else if (action === 'revokeAuthorization' && row) {
      await write.writeContractAsync({
        address: env.customClientAddress,
        abi: customClientAbi,
        functionName: 'revokeAuthorization',
        args: [row.authorized],
      });
    } else if (action === 'approveFor' && row) {
      await write.writeContractAsync({
        address: env.customClientAddress,
        abi: customClientAbi,
        functionName: 'approveFor',
        args: [row.owner, spender as `0x${string}`, parsedAmount],
      });
    } else {
      throw new Error('Invalid action state');
    }

    onClose();
  };

  if (!open) return null;

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="modal" onClick={(event) => event.stopPropagation()}>
        <div className="modal-header">
          <div>
            <h3>{row ? 'Manage authorization' : 'Create authorization'}</h3>
            <p className="muted">
              {row
                ? `${shortAddress(row.owner)} → ${shortAddress(row.authorized)}`
                : `Set a new ${symbol} authorization cap`}
            </p>
          </div>
          <button className="icon-button" onClick={onClose}>
            ×
          </button>
        </div>

        <label className="field">
          <span>Action</span>
          <select value={action} onChange={(event) => setAction(event.target.value as ActionKind)}>
            {availableActions.map((item) => (
              <option key={item} value={item}>
                {labels[item]}
              </option>
            ))}
          </select>
        </label>

        {/* New authorization: enter the delegate address */}
        {!row && action === 'authorize' ? (
          <label className="field">
            <span>Delegate address (authorized)</span>
            <input
              value={authorizedAddress}
              onChange={(event) => setAuthorizedAddress(event.target.value)}
              placeholder="0x..."
            />
          </label>
        ) : null}

        {/* Approve for: enter the spender address */}
        {action === 'approveFor' ? (
          <label className="field">
            <span>Spender address</span>
            <input
              value={spender}
              onChange={(event) => setSpender(event.target.value)}
              placeholder="0x..."
            />
          </label>
        ) : null}

        {action !== 'revokeAuthorization' ? (
          <label className="field">
            <span>Amount ({symbol})</span>
            <input
              value={amount}
              onChange={(event) => setAmount(event.target.value)}
              placeholder="0.0"
            />
          </label>
        ) : null}

        {write.error ? <p className="error-text">{write.error.message}</p> : null}

        <div className="modal-actions">
          <button className="secondary-button" onClick={onClose}>
            Cancel
          </button>
          <button className="primary-button" onClick={() => void submit()} disabled={write.isPending}>
            {write.isPending ? 'Confirm in wallet…' : labels[action]}
          </button>
        </div>
      </div>
    </div>
  );
};