import { AuthorizationRow, DashboardView } from '../types/authorization';
import { formatTokenAmount, shortAddress } from '../lib/format';

type Props = {
  rows: AuthorizationRow[];
  symbol: string;
  decimals: number;
  view: DashboardView;
  onAction: (row?: AuthorizationRow) => void;
};

export const AuthorizationTable = ({ rows, symbol, decimals, view, onAction }: Props) => {
  if (!rows.length) {
    return (
      <div className="empty-state">
        <p>No authorization records found for this view yet.</p>
        {view === 'grantedByMe' ? (
          <button className="primary-button" onClick={() => onAction(undefined)}>
            New authorization
          </button>
        ) : null}
      </div>
    );
  }

  return (
    <div className="table-wrap">
      <table>
        <thead>
          <tr>
            <th>{view === 'grantedByMe' ? 'Authorized' : 'Owner'}</th>
            <th>Current cap</th>
            <th>Total approved</th>
            <th>Last event</th>
            <th />
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.key}>
              <td>
                <div className="address-stack">
                  <span>{view === 'grantedByMe' ? shortAddress(row.authorized) : shortAddress(row.owner)}</span>
                  <small>{view === 'grantedByMe' ? row.authorized : row.owner}</small>
                </div>
              </td>
              <td>{formatTokenAmount(row.cap, decimals)} {symbol}</td>
              <td>{formatTokenAmount(row.totalApproved, decimals)} {symbol}</td>
              <td>{row.lastEventName ?? '—'}</td>
              <td className="row-actions">
                <button className="secondary-button" onClick={() => onAction(row)}>
                  Manage
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};
