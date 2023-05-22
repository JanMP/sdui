import React from 'react'
import {InputText} from 'primereact/inputtext'
import connectFieldPlus from '../../connectFieldPlus'
import {filterDOMProps} from 'uniforms'

export default connectFieldPlus ({
  name
  onChange
  value
  props...
}) ->

  <InputText
    value={value}
    onChange={(e) -> onChange e.target.value}
    {(filterDOMProps props)...}
  />