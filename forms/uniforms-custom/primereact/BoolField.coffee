import React from 'react'
import {Checkbox} from 'primereact/checkbox'
import connectFieldPlus from '../../connectFieldPlus'


export default connectFieldPlus ({
  name
  onChange
  value
  props...
}) ->

  <Checkbox
    onChange={(e) -> onChange e.checked}
    checked={value}
    {props...}
  />