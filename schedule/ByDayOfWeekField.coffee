import React from 'react'
import ReactSelect from 'react-select'
import connectFieldWithLabel from '../forms/connectFieldWithLabel.coffee'
import _ from 'lodash'

weekdayNames =
  SU: 'Sonntag'
  MO: 'Montag'
  TU: 'Dienstag'
  WE: 'Mittwoch'
  TH: 'Donnerstag'
  FR: 'Freitag'
  SA: 'Samstag'

weekdays = ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA']


options =
  _ [0..4]
  .map (interval) ->
    weekdays.map (weekday) ->
      value: if interval is 0 then weekday else [weekday, interval]
      label: if interval is 0 then "jeden #{weekdayNames[weekday]}" else "jeden #{interval}. #{weekdayNames[weekday]}"
  .flatten()
  .value()


ByDayOfWeekSelect = ({value, onChange}) ->

  optionsFromValue =
    unless value?.length
      []
    else
      value.map (v) ->
        options.find (o) ->
          (o is v) or ((o.value[0] is v[0]) and (o.value[1] is v[1]))

  handleChange = (valueOptions) ->
    console.log valueOptions
    unless valueOptions?.length
      onChange undefined
    else
      onChange valueOptions.map (o) -> o.value

  <ReactSelect
    options={options}
    value={optionsFromValue}
    onChange={handleChange}
    isMulti={true}
  />

export ByDayOfWeekField = connectFieldWithLabel ByDayOfWeekSelect