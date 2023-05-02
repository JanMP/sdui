import React, {useEffect} from 'react'
import {MultiSelect} from 'primereact/multiselect'
import connectFieldPlus from '../../connectFieldPlus'

export default connectFieldPlus ({
  value
  options
  display = 'text'
  onChange
  props...
}) ->

  useEffect ->
    console.log props
  , [props]

  <MultiSelect
    value={value}
    options={options}
    onChange={(e) -> onChange e.value}
    display={display}
    {props...}
  />