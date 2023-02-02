import React, {useEffect, useState} from 'react'
import {AutoForm, AutoField} from './uniforms-custom/select-implementation'
import SimpleSchema2Bridge from 'uniforms-bridge-simple-schema-2'
import _ from 'lodash'


export DynamicField = ({schemaBridge, fieldName, label, value, onChange, validate, mayEdit = true, className}) ->

  return null unless schemaBridge?.schema? and fieldName?

  value ?= null
  onChange ?= (value) -> console.log 'stub for onChange:', value
  className ?= 'dynamic-field'

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
      <AutoField name={fieldName} label={label} disabled={not mayEdit} className={className}/>
    </AutoForm>
  </div>
