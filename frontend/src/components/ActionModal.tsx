import { useMemo, useState } from 'react';
import { useWriteContract } from 'wagmi';
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
  const [action, setAction] = useState<ActionKind>(row ? 'increaseAuthorizedCap' : 'authorize');
  const [counterparty, setCounterparty] = useState(row?.authorized ?? '');
  const [recipient, setRecipient] = useState('');
  const [amount, setAmount] = useState('');
  const write = useWriteContract();

  const availableActions = useMemo<ActionKind[]>(() => {
    if (!row) return ['authorize'];
    if (view === 'grantedByMe') {
      return ['increaseAuthorizedCap', 'decreaseAuthorizedCap', 'revokeAuthorization'];
    }
    return ['approveFor'];
  }, [row, view]);

  const submit = async () => {
    const parsedAmount = amount ? parseTokenInput(amount, decimals) : 0n;

    if (action === 'authorize') {
      await write.writeContractAsync({
        address: env.customClientAddress,
        abi: customClientAbi,
        functionName: 'authorize',
        args: [counterparty as `0x${string}`, parsedAmount],
      });
    }

    if (action === 'increaseAuthorizedCap' && row) {
      await write.writeContractAsync({
        address: env.customClientAddress,
        abi: customClientAbi,
        functionName: 'increaseAuthorizedCap',
        args: [row.authorized, parsedAmount],
      });
    }

    if (action === 'decreaseAuthorizedCap' && row) {
      await write.writeContractAsync({
        address: env.customClientAddress,
        abi: customClientAbi,
        functionName: 'decreaseAuthorizedCap',
        args: [row.authorized, parsedAmount],
      });
    }

    if (action === 'revokeAuthorization' && row) {
      await write.writeContractAsync({
        address: env.customClientAddress,
        abi: customClientAbi,
        functionName: 'revokeAuthorization',
        args: [row.authorized],
      });
    }

    if (action === 'approveFor' && row) {
      await write.writeContractAsync({
        address: env.customClientAddress,
        abi: customClientAbi,
        functionName: 'approveFor',
        args: [row.owner, recipient as `0x${string}`, parsedAmount],
      });
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

        {!row && action === 'authorize' ? (
          <label className="field">
            <span>Authorized address</span>
            <input
              value={counterparty}
              onChange={(event) => setCounterparty(event.target.value)}
              placeholder="0x..."
            />
          </label>
        ) : null}

        {action === 'approveFor' ? (
          <label className="field">
            <span>Transfer recipient</span>
            <input
              value={recipient}
              onChange={(event) => setRecipient(event.target.value)}
              placeholder="0x..."
            />
          </label>
        ) : null}

        {action !== 'revokeAuthorization' ? (
          <label className="field">
            <span>Amount ({symbol})</span>
            <input value={amount} onChange={(event) => setAmount(event.target.value)} placeholder="0.0" />
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
