import React from 'react'
import {Dropdown} from 'primereact/dropdown'
import connectFieldPlus from '../../connectFieldPlus'
import {filterDOMProps} from 'uniforms'


Select = ({
  allowedValues
  disabled
  name
  onChange
  readOnly
  value
  props...
})->

  props.options ?= allowedValues

  <Dropdown
    disabled={disabled}
    onChange={(e) -> onChange e.value}
    style={minWidh: '100%', maxWidth: '100%'}
    value={value}
    {props...}
  />

export default connectFieldPlus Select