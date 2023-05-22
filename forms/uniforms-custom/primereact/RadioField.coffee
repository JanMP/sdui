import React from 'react'
import connectFieldPlus from '../../connectFieldPlus'
import {RadioButton} from 'primereact/radiobutton'
import {filterDOMProps} from 'uniforms'

export default connectFieldPlus ({
  allowedValues
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
            id={idString}
            name={name}
            value={item}
            checked={item is value}
            onChange={-> onChange item}
            {(filterDOMProps props)...}
          />
          <label htmlFor={idString}>{item}</label>
        </div>
    }
  </div>