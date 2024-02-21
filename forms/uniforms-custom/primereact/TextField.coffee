import React from 'react'
import {InputText} from 'primereact/inputtext'
import connectFieldPlus from '../../connectFieldPlus'
import {filterDOMProps} from 'uniforms'

export default connectFieldPlus ({
  name
  disabled
  onChange
  value
  props...
}) ->

  <InputText
    disabled={disabled}
    value={value ? ""}
    onChange={(e) -> onChange e.target.value}
    {(filterDOMProps props)...}
  />