import { DashboardView } from '../types/authorization';

type Props = {
  value: DashboardView;
  onChange: (value: DashboardView) => void;
};

export const ViewTabs = ({ value, onChange }: Props) => {
  return (
    <div className="tabs" role="tablist" aria-label="Authorization views">
      <button
        className={value === 'grantedByMe' ? 'tab active' : 'tab'}
        onClick={() => onChange('grantedByMe')}
      >
        Granted By Me
      </button>
      <button
        className={value === 'grantedToMe' ? 'tab active' : 'tab'}
        onClick={() => onChange('grantedToMe')}
      >
        Granted To Me
      </button>
    </div>
  );
};
