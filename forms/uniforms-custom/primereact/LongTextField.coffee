import React from 'react'
import {InputTextarea} from 'primereact/inputtextarea'
import connectFieldPlus from '../../connectFieldPlus'
import {filterDOMProps} from 'uniforms'

export default connectFieldPlus ({
  disabled
  name
  onChange
  value
  props...
}) ->

  <InputTextarea
    disabled={disabled}
    onChange={(e) -> onChange e.target.value}
    value={value}
    {(filterDOMProps props)...}
  />