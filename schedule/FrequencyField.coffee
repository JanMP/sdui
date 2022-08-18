import React from 'react'
import ReactSelect from 'react-select'
import connectFieldWithLabel from '../forms/connectFieldWithLabel.coffee'

options = [
  value: 'YEARLY'
  label: 'Jährlich'
,
  value: 'MONTHLY'
  label: 'Monatlich'
,
  value: 'WEEKLY'
  label: 'Wöchentlich'
,
  value: 'DAILY'
  label: 'Täglich'
,
  value: 'HOURLY'
  label: 'Stündlich'
,
  value: 'MINUTELY'
  label: 'Minütlich'
,
  value: 'SECONDLY'
  label: 'Sekündlich'
]

FrequencySelect = ({value, onChange}) ->

  optionFromValue = (value) -> options.find (o) -> o.value is value

  handleChange= (option) -> onChange option.value

  <ReactSelect
    options={options}
    value={optionFromValue value}
    onChange={handleChange}

  />

export FrequencyField = connectFieldWithLabel FrequencySelect