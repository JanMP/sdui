import React, { ReactNode } from 'react';
import { connectField } from 'uniforms';

import AutoField from './AutoField';
import ListDelField from './ListDelField';

export type ListItemFieldProps = { children?: ReactNode; value?: unknown };

function ListItem({
  children = <AutoField label={null} name="" />,
}: ListItemFieldProps) {
  return (
    <div className="p-card p-3 mb-3 mx-2 flex flex-row align-items-center gap-4">
      <div className="flex-grow-1">{children}</div>
      <div>
        <ListDelField name="" />
      </div>
    </div>
  );
}

export default connectField<ListItemFieldProps>(ListItem, {
  initialValue: false,
});
