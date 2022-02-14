import React, { Ref } from 'react';
import { HTMLFieldProps, connectField, filterDOMProps } from 'uniforms';
import setClassNamesForProps from './setClassNamesForProps';

export type BoolFieldProps = HTMLFieldProps<
  boolean,
  HTMLDivElement,
  { inputRef?: Ref<HTMLInputElement> }
>;

function Bool({
  disabled,
  id,
  inputRef,
  label,
  name,
  onChange,
  readOnly,
  value,
  ...props
}: BoolFieldProps) {
  return (
    <div className={setClassNamesForProps(props)} {...filterDOMProps(props)}>
      <input
        checked={value || false}
        disabled={disabled}
        id={id}
        name={name}
        onChange={() => !disabled && !readOnly && onChange(!value)}
        ref={inputRef}
        type="checkbox"
      />

      {label && <label htmlFor={id}>{label}</label>}
    </div>
  );
}

export default connectField<BoolFieldProps>(Bool, { kind: 'leaf' });
