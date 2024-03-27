import { Thumbs } from './ThumbsField.coffee'
import React, {useState} from 'react'
import {Button} from 'primereact/button'
import {FormModal} from './FormModal.coffee'
import SimpleSchema from 'meteor/aldeed:simple-schema'
import SimpleSchemaBridge from 'uniforms-bridge-simple-schema-2'
import LongTextField from './uniforms-custom/primereact/LongTextField.coffee'
import {ThumbsField} from './ThumbsField.coffee'
import connectFieldPlus from './connectFieldPlus.coffee'

SimpleSchema.extendOptions(['uniforms'])

formSchema = new SimpleSchema
  thumbs:
    type: String
    optional: true
    uniforms:
      component: ThumbsField
  comment:
    type: String
    optional: true
    uniforms:
      component: LongTextField

formSchemaBridge = new SimpleSchemaBridge formSchema

export FeedbackButton = ({value, onChange}) ->

  [modalOpen, setModalOpen] = useState false

  upColor = if value?.thumbs is 'up' then 'green' else 'grey'
  downColor = if value?.thumbs is 'down' then 'red' else 'grey'

  submitAndClose = (data) ->
    onChange data
    setModalOpen false


  handleClick = (event) ->
    event.preventDefault()
    event.stopPropagation()
    setModalOpen true

  <>
    <FormModal
      schemaBridge={formSchemaBridge}
      onSubmit={submitAndClose}
      model={value}
      isOpen={modalOpen}
      onRequestClose={-> setModalOpen false}
    />
    <Button onClick={handleClick} rounded text>
      <i className="pi pi-thumbs-up" style={color: upColor}></i>
      <i className="ml-2 pi pi-thumbs-down" style={color: downColor}></i>
    </Button>
  </>


export FeedbackButtonField = connectFieldPlus ({value, onChange}) ->

  <div className="p-component p-card w-full p-4">
    <FeedbackButton value={value} onChange={onChange}/>
  </div>

export FeedbackButtonTableField = ({row, columnKey, schemaBridge, onChangeField, measure, mayEdit}) ->
  onChange = (d) ->
    onChangeField
      _id: row?._id ? row?.id
      changeData: "#{columnKey}": d

  <FeedbackButton value={row[columnKey]} onChange={onChange} />