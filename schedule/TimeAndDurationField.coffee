import React from 'react'
import {AutoForm, AutoField} from '../forms/uniforms-custom/select-implementation'
import {connectField} from 'uniforms'
import SimpleSchema from 'simpl-schema'
import SimpleSchema2Bridge from 'uniforms-bridge-simple-schema-2'
import TimeField from '../forms/uniforms-custom/src/TimeField.tsx'
import DateField from '../forms/uniforms-custom/src/DateField.tsx'

schema = new SimpleSchema
  start:
    type: Date
    uniforms:
      component: TimeField
  duration:
    type: String
    uniforms:
      component: TimeField

schemaBridge = new SimpleSchema2Bridge schema

TimeAndDuration = ({value, onChange}) ->
  <AutoForm
    schema={schemaBridge}
    model={value}
    onChangeModel={onChange}
  >
    <div className="grid grid-cols-2 gap-4">
      <div>
        <AutoField name="start"/>
      </div>
      <div>
        <AutoField name="duration"/>
      </div>
    
    </div>

  </AutoForm>

export TimeAndDurationField = connectField TimeAndDuration