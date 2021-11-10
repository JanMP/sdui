import React, {useEffect, useState} from 'react'
import AutoForm from './uniforms-custom/AutoForm'
import AutoField from './uniforms-custom/AutoField'
import {connectField} from 'uniforms'
import SimpleSchema2Bridge from 'uniforms-bridge-simple-schema-2'
import _ from 'lodash'


export default DynamicField = ({schemaBridge, fieldName, label, value, onChange, validate, mayEdit = true}) ->

  return null unless schemaBridge?.schema? and fieldName?

  value ?= null
  onChange ?= (value) -> console.log 'onChange:', value

  schemaBridgeForFieldName = new SimpleSchema2Bridge schemaBridge.schema?.pick fieldName

  onClick = (e) ->
    e.stopPropagation()
    e.nativeEvent.stopImmediatePropagation()

  handleChange = (model) ->
    modelValue = model[fieldName]
    unless _.isEqual value, modelValue
      onChange modelValue

  <div onClick={onClick}>
    <AutoForm
      schema={schemaBridgeForFieldName}
      model={"#{fieldName}": value}
      onChangeModel={handleChange}
      validate={validate}
    >
      <AutoField name={fieldName} label={label} disabled={not mayEdit}/>
    </AutoForm>
  </div>
