import React from 'react'
import {Calendar} from 'primereact/calendar'
import {filterDOMProps} from 'uniforms'
import connectFieldPlus from '../../connectFieldPlus'

Date = ({
  disabled
  id
  inputRef
  label
  max
  min
  name
  onChange,
  placeholder
  readOnly
  value
  props...
}) ->

  <Calendar
    id={id}
    value={value}
    onChange={(e) -> onChange e.value}
    {props...}
  />

export default connectFieldPlus Date