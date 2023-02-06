import React from 'react'
import {InputText} from 'primereact/inputtext'
import {filterDOMProps} from 'uniforms'
import connectFieldPlus from '../../connectFieldPlus'

Text = ({
  disabled
  id
  inputRef
  label
  max
  min
  name
  onChange,
  placeholder
  readOnly
  value
  className
}) ->

  <InputText
    id={id}
    value={value}
    onChange={(e) -> onChange e.value}
    className={className}
  />

export default connectFieldPlus Text