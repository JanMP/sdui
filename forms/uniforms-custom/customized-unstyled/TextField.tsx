import React, { Ref } from 'react';
import { HTMLFieldProps, connectField, filterDOMProps } from 'uniforms';
import setClassNamesForProps from './setClassNamesForProps';
import {useTranslation} from 'react-i18next'

export type TextFieldProps = HTMLFieldProps<
string,
HTMLDivElement,
{ inputRef?: Ref<HTMLInputElement>; hasFloatingLabel?: boolean }
>;

function Text({
  autoComplete,
  disabled,
  id,
  inputRef,
  label,
  name,
  onChange,
  placeholder,
  readOnly,
  type,
  value,
  ...props
}: TextFieldProps) {
  
  const {t} = useTranslation()

  return (
    <div className={setClassNamesForProps(props)} {...filterDOMProps(props)}>
      {label && !props.hasFloatingLabel && <label htmlFor={id}>{t(label)}</label>}
      <input
        autoComplete={autoComplete}
        disabled={disabled}
        id={id}
        name={name}
        onChange={event => onChange(event.target.value)}
        placeholder={placeholder}
        readOnly={readOnly}
        ref={inputRef}
        type={type}
        value={value ?? ''}
      />
      {label && props.hasFloatingLabel && <label htmlFor={id}>{t(label)}</label>}
    </div>
  );
}

Text.defaultProps = { type: 'text' };

export default connectField<TextFieldProps>(Text, { kind: 'leaf' });
