import React from 'react'
import {Dropdown} from 'primereact/dropdown'
import connectFieldPlus from '../../connectFieldPlus'
import {filterDOMProps} from 'uniforms'


Select = ({
  allowedValues
  name
  onChange
  readOnly
  value
  props...
})->

  props.options ?= allowedValues

  <Dropdown
    value={value}
    onChange={(e) -> onChange e.value}
    style={minWidh: '100%', maxWidth: '100%'}
    {(filterDOMProps props)...}
  />

export default connectFieldPlus Select