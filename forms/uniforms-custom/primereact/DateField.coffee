import React from 'react'
import {Calendar} from 'primereact/calendar'
import connectFieldPlus from '../../connectFieldPlus'
import {useTranslation} from 'react-i18next'
import {filterDOMProps} from 'uniforms'

#TODO: bypass FilterDOMProps for some needed props
export default connectFieldPlus ({
  useLocalTimeZone = false
  dateFormat
  disabled
  max
  maxDate
  min
  minDate
  name
  onChange
  value
  props...
}) ->

  {t} = useTranslation()
  
  dateFormat ?= t 'dd.mm.yy'
  minDate ?= min
  maxDate ?= max

  offset =
    unless useLocalTimeZone
      try
        value.getTimezoneOffset() * 60 * 1000
      catch e
        0
    else
      0

  fixedInputValue =
    try
      new Date(value.getTime() + offset)
    catch error
      value

  outputFixedValue = ({value}) ->
    fixedOutputValue =
      try
        new Date(value.getTime() - offset)
      catch error
        value
    onChange fixedOutputValue


  <Calendar
    dateFormat={dateFormat}
    disabled={disabled}
    maxDate={maxDate}
    minDate={minDate}
    onChange={outputFixedValue}
    value={fixedInputValue}
    {props...}
  />