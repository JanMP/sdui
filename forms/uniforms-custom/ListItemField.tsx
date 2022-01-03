import React, { ReactNode } from 'react';
import { connectField } from 'uniforms';

import AutoField from './AutoField';
import ListDelField from './ListDelField';

export type ListItemFieldProps = { children?: ReactNode; value?: unknown };

function ListItem({
  children = <AutoField label={null} name="" />,
}: ListItemFieldProps) {
  return (
    <div className="u-list-item-field">
      <div className="u-list-item-child-container">{children}</div>
      <div>
        <ListDelField name="" />
      </div>
    </div>
  );
}

export default connectField<ListItemFieldProps>(ListItem, {
  initialValue: false,
});
