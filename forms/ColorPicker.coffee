import React from 'react'
import {connectField, filterDOMProps} from 'uniforms'
import setErrorClass from './uniforms-custom/setErrorClass'

export ColorPicker = ({
  disabled, fieldType, id, inputRef, label, name,
  onChange, readOnly, required, value, props...
}) ->

  <div {(filterDOMProps props)...}>
    {<label htmlFor={id}>{label}</label> if label?}
    
    <input
      id={id}
      className={setErrorClass props}
      type="color"
      disabled={disabled}
      name={name}
      readOnly={readOnly}
      onChange={(event) -> onChange event.target.value}
      value={value ? 'pink'}
    />
  </div>


export ColorPickerField = connectField ColorPicker, kind: 'leaf'