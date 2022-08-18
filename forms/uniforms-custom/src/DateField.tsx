import React, { Ref } from 'react';
import { HTMLFieldProps, connectField, filterDOMProps } from 'uniforms';
import setClassNamesForProps from './setClassNamesForProps';
import {DateTime} from 'luxon'
import DatePicker from 'react-date-picker'



export type DateFieldProps = HTMLFieldProps<
  Date,
  HTMLDivElement,
  { inputRef?: Ref<HTMLInputElement>; max?: Date; min?: Date; hasFloatingLabel?: boolean }
>;

function Date({
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
  value,
  hasFloatingLabel,
  ...props
}: DateFieldProps) {
  return (
    <div className={setClassNamesForProps(props)} {...filterDOMProps(props)}>
      {label && !hasFloatingLabel &&<label htmlFor={id}>{label}</label>}
      
      <DatePicker
        value={value}
        onChange={onChange}
        disabled={disabled}
        format="dd.MM.y"
        locale="de-DE"
        disableCalendar={true}
        minDate={min}
        maxDate={max}
        dayPlaceholder="tt"
        monthPlaceholder="mm"
        yearPlaceholder="jjjj"
      />
    
      {label && hasFloatingLabel &&<label htmlFor={id}>{label}</label>}
    </div>
  );
}

export default connectField<DateFieldProps>(Date, { kind: 'leaf' });
