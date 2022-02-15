import React, { Ref } from 'react';
import { HTMLFieldProps, connectField, filterDOMProps } from 'uniforms';
import setClassNamesForProps from './setClassNamesForProps';

export type NumFieldProps = HTMLFieldProps<
  number,
  HTMLDivElement,
  { decimal?: boolean; inputRef?: Ref<HTMLInputElement>; hasFloatingLabel?: boolean }
>;

function Num({
  decimal,
  disabled,
  id,
  inputRef,
  label,
  max,
  min,
  name,
  onChange,
  placeholder,
  readOnly,
  step,
  value,
  ...props
}: NumFieldProps) {
  return (
    <div className={setClassNamesForProps(props)} {...filterDOMProps(props)}>
      {label && !props.hasFloatingLabel && <label htmlFor={id}>{label}</label>}
      <input
        disabled={disabled}
        id={id}
        max={max}
        min={min}
        name={name}
        onChange={event => {
          const parse = decimal ? parseFloat : parseInt;
          const value = parse(event.target.value);
          onChange(isNaN(value) ? undefined : value);
        }}
        placeholder={placeholder}
        readOnly={readOnly}
        ref={inputRef}
        step={step || (decimal ? 0.01 : 1)}
        type="number"
        value={value ?? ''}
      />
      {label && props.hasFloatingLabel && <label htmlFor={id}>{label}</label>}
    </div>
  );
}

export default connectField<NumFieldProps>(Num, { kind: 'leaf' });
