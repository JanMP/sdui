import React from 'react'
import {InputTextarea} from 'primereact/inputtextarea'
import connectFieldPlus from '../../connectFieldPlus'


export default connectFieldPlus ({
  name
  onChange
  props...
}) ->

  <InputTextarea
    onChange={(e) -> onChange e.target.value}
    {props...}
  />