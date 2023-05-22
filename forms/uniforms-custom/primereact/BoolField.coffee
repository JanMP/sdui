import React from 'react'
import {Checkbox} from 'primereact/checkbox'
import connectFieldPlus from '../../connectFieldPlus'
import {filterDOMProps} from 'uniforms'


export default connectFieldPlus ({
  name
  disabled
  onChange
  value
  props...
}) ->

  <Checkbox
    onChange={(e) -> onChange e.checked}
    checked={value}
    disabled={disabled}
    {(filterDOMProps props)...}
  />