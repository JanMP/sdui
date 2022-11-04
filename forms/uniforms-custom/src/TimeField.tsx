import React, { Ref } from 'react';
import { HTMLFieldProps, connectField, filterDOMProps } from 'uniforms';
import setClassNamesForProps from './setClassNamesForProps';
import {DateTime} from 'luxon'
import TimePicker from 'react-time-picker'
import {useTranslation} from 'react-i18next'

export type TimeFieldProps = HTMLFieldProps<
Date,
HTMLDivElement,
{ inputRef?: Ref<HTMLInputElement>; max?: Date; min?: Date; hasFloatingLabel?: boolean }
>;

function Time({
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
}: TimeFieldProps) {
  
  const {t} = useTranslation()

  return (
    <div className={setClassNamesForProps(props)} {...filterDOMProps(props)}>
      {label && !hasFloatingLabel &&<label htmlFor={id}>{t(label)}</label>}
      
      <TimePicker
        value={value}
        onChange={onChange}
        disabled={disabled}
        format="HH:mm:ss"
        locale="de-DE"
        disableClock={true}
        minTime={min}
        maxTime={max}
        hourPlaceholder="hh"
        minutePlaceholder="mm"
        secondPlaceholder="ss"
        maxDetail="second"
      />
    
      {label && hasFloatingLabel &&<label htmlFor={id}>{t(label)}</label>}
    </div>
  );
}

export default connectField<TimeFieldProps>(Time, { kind: 'leaf' });
