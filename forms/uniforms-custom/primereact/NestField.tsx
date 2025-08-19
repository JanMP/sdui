import React from 'react';
import { HTMLFieldProps, connectField, filterDOMProps } from 'uniforms';
import {Fieldset} from 'primereact/fieldset';
import AutoField from './AutoField';

export type NestFieldProps = HTMLFieldProps<
  object,
  HTMLDivElement,
  { itemProps?: object }
>;

function Nest({
  children,
  fields,
  itemProps,
  label,
  ...props
}: NestFieldProps) {
  return (
    <Fieldset legend={label} {...filterDOMProps(props)} className="mt-4">
      {children ||
        fields.map(field => (
          <AutoField key={field} name={field} {...itemProps} />
        ))}
    </Fieldset>
  );
}

export default connectField<NestFieldProps>(Nest);
