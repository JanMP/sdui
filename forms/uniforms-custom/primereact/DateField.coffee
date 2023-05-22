import React from 'react'
import {Calendar} from 'primereact/calendar'
import connectFieldPlus from '../../connectFieldPlus'
import {useTranslation} from 'react-i18next'
import {filterDOMProps} from 'uniforms'

#TODO: bypass FilterDOMProps for some needed props
export default connectFieldPlus ({
  max
  min
  name
  onChange
  props...
}) ->

  {t} = useTranslation()
  
  props.dateFormat ?= t 'dd.mm.yy'
  props.minDate ?= min
  props.maxDate ?= max

  <Calendar
    onChange={(e) -> onChange e.value}
    {(filterDOMProps props)...}
  />