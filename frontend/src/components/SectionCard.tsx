import { PropsWithChildren, ReactNode } from 'react';

type Props = PropsWithChildren<{
  title: string;
  subtitle?: string;
  rightSlot?: ReactNode;
}>;

export const SectionCard = ({ title, subtitle, rightSlot, children }: Props) => {
  return (
    <section className="card">
      <div className="card-header">
        <div>
          <h2>{title}</h2>
          {subtitle ? <p className="muted">{subtitle}</p> : null}
        </div>
        {rightSlot ? <div>{rightSlot}</div> : null}
      </div>
      {children}
    </section>
  );
};
