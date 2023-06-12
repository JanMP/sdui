import React from 'react'
import {Password} from 'primereact/password'
import connectFieldPlus from '../../connectFieldPlus'
import {filterDOMProps} from 'uniforms'

export default connectFieldPlus ({
  name
  disabled
  onChange
  value
  props...
}) ->

  <Password
    disabled={disabled}
    value={value}
    onChange={(e) -> onChange e.target.value}
    {(filterDOMProps props)...}
    toggleMask={true}
    feedback={true}
  />