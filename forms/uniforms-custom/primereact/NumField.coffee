import React from 'react'
import {InputNumber} from 'primereact/inputnumber'
import connectFieldPlus from '../../connectFieldPlus'


export default connectFieldPlus ({
  decimal
  useGrouping = false
  name
  onChange
  props...
}) ->

  if decimal
    props.minFractionDigits ?= 1

  <InputNumber
    onChange={(e) -> onChange e.value}
    useGrouping={useGrouping}
    {props...}
  />