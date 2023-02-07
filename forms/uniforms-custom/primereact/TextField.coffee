import React from 'react'
import {InputText} from 'primereact/inputtext'
import connectFieldPlus from '../../connectFieldPlus'


export default connectFieldPlus ({
  name
  onChange
  props...
}) ->

  <InputText
    onChange={(e) -> onChange e.target.value}
    {props...}
  />