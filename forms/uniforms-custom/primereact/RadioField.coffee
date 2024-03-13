import React from 'react'
import connectFieldPlus from '../../connectFieldPlus'
import {RadioButton} from 'primereact/radiobutton'
import {filterDOMProps} from 'uniforms'

export default connectFieldPlus ({
  allowedValues
  disabled
  id
  name
  onChange
  value
  props...
}) ->

  <div>
    {
      allowedValues.map (item) ->
      
        idString = "#{id}-#{item}"
        
        <div className="radio-button-field" key={item}>
          <RadioButton
            checked={item is value}
            disabled={disabled}
            id={idString}
            name={name}
            onChange={-> onChange item}
            value={item}
            {props...}
          />
          <label htmlFor={idString}>{item}</label>
        </div>
    }
  </div>