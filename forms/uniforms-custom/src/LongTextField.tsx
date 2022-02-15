import React, { Ref } from 'react';
import { HTMLFieldProps, connectField, filterDOMProps } from 'uniforms';
import setClassNamesForProps from './setClassNamesForProps';

export type LongTextFieldProps = HTMLFieldProps<
  string,
  HTMLDivElement,
  { inputRef?: Ref<HTMLTextAreaElement>; hasFloatingLabel?: boolean }
>;

function LongText({
  disabled,
  id,
  inputRef,
  label,
  name,
  onChange,
  placeholder,
  readOnly,
  value,
  ...props
}: LongTextFieldProps) {
  return (
    <div className={setClassNamesForProps(props)} {...filterDOMProps(props)}>
      {label && !props.hasFloatingLabel && <label htmlFor={id}>{label}</label>}
      <textarea
        disabled={disabled}
        id={id}
        name={name}
        onChange={event => onChange(event.target.value)}
        placeholder={placeholder}
        readOnly={readOnly}
        ref={inputRef}
        value={value ?? ''}
      />
      {label && props.hasFloatingLabel && <label htmlFor={id}>{label}</label>}
    </div>
  );
}

export default connectField<LongTextFieldProps>(LongText, { kind: 'leaf' });
