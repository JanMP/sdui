import React from 'react';
import { HTMLFieldProps, connectField, filterDOMProps } from 'uniforms';
import AutoField from './AutoField';
import {useTranslation} from 'react-i18next'

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
  
  const{t} = useTranslation()
  
  return (
    <div {...filterDOMProps(props)}>
      {label && <label>{t(label)}</label>}
      {children ||
        fields.map(field => (
          <AutoField key={field} name={field} {...itemProps} />
        ))}
    </div>
  );
}

export default connectField<NestFieldProps>(Nest);
