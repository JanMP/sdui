import React from 'react'
import {InputTextarea} from 'primereact/inputtextarea'
import connectFieldPlus from '../../connectFieldPlus'
import {filterDOMProps} from 'uniforms'

export default connectFieldPlus ({
  name
  onChange
  props...
}) ->

  <InputTextarea
    onChange={(e) -> onChange e.target.value}
    {(filterDOMProps props)...}
  />