import React, {useEffect} from 'react'
import {MultiSelect} from 'primereact/multiselect'
import connectFieldPlus from '../../connectFieldPlus'
import {filterDOMProps} from 'uniforms'

export default connectFieldPlus ({
  disabled
  display = 'text'
  onChange
  options
  value
  props...
}) ->

  <MultiSelect
    disabled={disabled}
    display={display}
    options={options}
    onChange={(e) -> onChange e.value}
    value={value}
    {(filterDOMProps props)...}
  />