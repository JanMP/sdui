import React from 'react'
import {Dropdown} from 'primereact/dropdown'
import connectFieldPlus from '../../connectFieldPlus'

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
    {props...}
  />

export default connectFieldPlus Select