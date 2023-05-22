import React from 'react'
import {InputTextarea} from 'primereact/inputtextarea'
import connectFieldPlus from '../../connectFieldPlus'
import {filterDOMProps} from 'uniforms'

export default connectFieldPlus ({
  name
  onChange
  value
  props...
}) ->

  <InputTextarea
    onChange={(e) -> onChange e.target.value}
    value={value}
    {(filterDOMProps props)...}
  />