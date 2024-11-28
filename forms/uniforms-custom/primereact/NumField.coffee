import React from 'react'
import {InputNumber} from 'primereact/inputnumber'
import connectFieldPlus from '../../connectFieldPlus'
import {filterDOMProps} from 'uniforms'

export default connectFieldPlus ({
  decimal
  useGrouping = false
  name
  onChange
  value
  props...
}) ->
  console.log props
  if decimal
    props.minFractionDigits ?= 1

  <InputNumber
    value={value}
    onValueChange={(e) -> onChange e.value}
    useGrouping={useGrouping}
    {props...}
  />