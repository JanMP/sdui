import React, {useState, useEffect} from 'react'
import ReactSelect from 'react-select'
import connectFieldWithLabel from '../forms/connectFieldWithLabel.coffee'
import _ from 'lodash'

CommaSeparatedNumbersInput = ({value, onChange}) ->

  valueAsString = value.join ','

  [inputValue, setInputValue] = useState valueAsString
  [oldValue, setOldValue] = useState valueAsString

  useEffect ->
    setOldValue value
    unless _.isEqual value, oldValue
      setInputValue value.join ','
  , [value]

  useEffect ->
  , [inputValue]

  handleChange = (e) ->
    newInputValue = e.target.value
    setInputValue newInputValue
    newValue =
      newInputValue
      .split(',')
      .map (s) -> _.parseInt s
    onChange _.compact newValue

  <input
    value={inputValue}
    onChange={handleChange}
  />

export CommaSeparatedNumbersField = connectFieldWithLabel CommaSeparatedNumbersInput