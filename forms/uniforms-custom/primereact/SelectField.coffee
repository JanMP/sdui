import React from 'react'
import {Dropdown} from 'primereact/dropdown'
import connectFieldPlus from '../../connectFieldPlus'
import {filterDOMProps} from 'uniforms'

#TODO: add multi-select support?


Select = ({
  allowedValues
  name
  onChange
  readOnly
  props...
})->

  props.options ?= allowedValues

  <Dropdown
    onChange={(e) -> onChange e.value}
    style={minWidh: '100%', maxWidth: '100%'}
    {(filterDOMProps props)...}
  />

export default connectFieldPlus Select