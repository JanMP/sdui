import React from 'react'
import {Calendar} from 'primereact/calendar'
import connectFieldPlus from '../../connectFieldPlus'
import {useTranslation} from 'react-i18next'
import {filterDOMProps} from 'uniforms'

#TODO: bypass FilterDOMProps for some needed props
export default connectFieldPlus ({
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

  <Calendar
    dateFormat={dateFormat}
    disabled={disabled}
    maxDate={maxDate}
    minDate={minDate}
    onChange={(e) -> onChange e.value}
    value={value}
    {(filterDOMProps props)...}
  />