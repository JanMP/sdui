import invariant from 'invariant'
import {createAutoField} from 'uniforms'
export {AutoFieldProps} from 'uniforms'

import BoolField from './BoolField'
import DateField from './DateField'
import ListField from './ListField'
import NestField from './NestField'
import NumField from './NumField'
import RadioField from './RadioField'
import SelectField from './SelectField'
import TextField from './TextField'

export default createAutoField (props) ->
  if props.allowedValues
    if props.checkboxes and props.fieldType isnt Array
      RadioField
    else
      SelectField
  else
    switch props.fieldType
      when Array
        ListField
      when Boolean
        BoolField
      when Date
        DateField
      when Number
        NumField
      when Object
        NestField
      when String
        TextField
      else
        invariant false, 'Unsupported field type: %s', props.fieldType

