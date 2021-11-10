import React, { Ref } from 'react';
import { HTMLFieldProps, connectField, filterDOMProps } from 'uniforms';
import setErrorClass from './setErrorClass'

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
  labelLinkTo,
  name,
  onChange,
  readOnly,
  value,
  ...props
}: BoolFieldProps) {
  return (
    <div {...filterDOMProps(props)}>
      <input
        className={setErrorClass(props)}
        checked={value || false}
        disabled={disabled}
        id={id}
        name={name}
        onChange={() => !disabled && !readOnly && onChange(!value)}
        ref={inputRef}
        type="checkbox"
      />

      {label && <label htmlFor={id}>{
        labelLinkTo ? <a href={labelLinkTo}>{label}</a> : label
      }</label>}
    </div>
  );
}

export default connectField(Bool, { kind: 'leaf' });
