import React, {useState} from 'react'
import SimpleSchema from 'simpl-schema'
import SimpleSchema2Bridge from 'uniforms-bridge-simple-schema-2'
import {AutoForm, AutoField} from '../forms/uniforms-custom/select-implementation'
import {connectField} from 'uniforms'
import {FrequencyField} from './FrequencyField.coffee'
import {ByDayOfWeekField} from './ByDayOfWeekField.coffee'
import {CommaSeparatedNumbersField} from './CommaSeparatedNumbersField.coffee'
import {TimeAndDurationField} from './TimeAndDurationField.coffee'
import TimeField from '../forms/uniforms-custom/src/TimeField.tsx'
import DateField from '../forms/uniforms-custom/src/DateField.tsx'
import _ from 'lodash'



weekdayNames =
  SU: 'Sonntag'
  MO: 'Montag'
  TU: 'Dienstag'
  WE: 'Mittwoch'
  TH: 'Donnerstag'
  FR: 'Freitag'
  SA: 'Samstag'

schema = new SimpleSchema
  start:
    type: Date
    label: 'Start Datum'
    uniforms:
      component: DateField
  times:
    type: Array
  'times.$':
    type: Object
    blackbox: true
    uniforms:
      component: TimeAndDurationField
  end:
    type: Date
    optional: true
    label: 'End Datum'
    uniforms:
      component: DateField
  count:
    type: Number
    optional: true
    label: "Anzahl der Termine"
  frequency:
    type: String
    uniforms:
      component: FrequencyField
    label: 'Widerholungsfrequenz'
  interval:
    type: Number
    optional: true
  byDayOfWeek:
    type: Array
    optional: true
    uniforms:
      component: ByDayOfWeekField
  'byDayOfWeek.$':
    type: Object
    blackbox: true
  byMinuteOfHour:
    type: Array
    optional: true
    uniforms:
      component: CommaSeparatedNumbersField
  'byMinuteOfHour.$':
    type: Number
  byHourOfDay:
    type: Array
    optional: true
    uniforms:
      component: CommaSeparatedNumbersField
  'byHourOfDay.$':
    type: Number
  byDayOfMonth:
    type: Array
    optional: true
    uniforms:
      component: CommaSeparatedNumbersField
  'byDayOfMonth.$':
    type: Number
    optional: true
  byMonthOfYear:
    type: Array
    optional: true
    uniforms:
      component: CommaSeparatedNumbersField
  'byMonthOfYear.$':
    type: Number
    optional: true

schemaBridge = new SimpleSchema2Bridge schema


export RRuleEditor = ({model, onChangeModel}) ->

  <AutoForm
    schema={schemaBridge}
    model={model}
    onChangeModel={onChangeModel}
    submitField={-> null}
  />

export RRuleEditorField = connectField RRuleEditor, kind: 'leaf'