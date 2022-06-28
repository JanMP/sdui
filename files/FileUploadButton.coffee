import React, {useEffect, useState} from 'react'
import {meteorApply} from '../common/meteorApply.coffee'
import {useCurrentUserIsInRole} from '../common/roleChecks.coffee'
import SimpleSchema from 'simpl-schema'
import SimpleSchema2Bridge from 'uniforms-bridge-simple-schema-2'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faPlus} from '@fortAwesome/free-solid-svg-icons/faPlus'
import {toast} from 'react-toastify'
import {FileInputField} from './FileInput.coffee'
import {FormModal} from '../forms/FormModal.coffee'
import compact from 'lodash/compact'

SimpleSchema.extendOptions ['sdTable', 'uniforms']

export FileUploadButton = ({dataOptions}) ->
  
  {tableDataOptions, roles} = dataOptions
  {uploadUserFilesRole, uploadCommonFilesRole} = roles

  useEffect ->
    console.log dataOptions
  , [dataOptions]

  [formModalIsOpen, setFormModalIsOpen] = useState false

  mayUploadCommonFiles = useCurrentUserIsInRole uploadCommonFilesRole
  mayUploadUserFiles = useCurrentUserIsInRole uploadUserFilesRole

  uploadAsOptions = compact [
    if mayUploadCommonFiles then 'public'
    if mayUploadUserFiles then 'private'
  ]

  freshModel =
    uploadAs: uploadAsOptions[0]

  send = ({model, sourceName}) ->
    {original, thumbnail} = model.file
    Promise.allSettled compact([original, thumbnail]).map (file) ->
      {name, size, type} = file
      saveAsCommon = model.uploadAs is 'public'
      meteorApply
        method: "#{sourceName}.requestUpload"
        data: {name, size, type, saveAsCommon}
      .then ({uploadUrl, key}) ->
        response =
          await fetch uploadUrl,
            method: 'PUT'
            headers:
              'Content-Type': type
              'x-amz-acl': 'public-read'
            body: file
        {response, key}
      .then ({response, key}) ->
        console.log {key, response}
        meteorApply
          method: "#{sourceName}.finishUpload"
          data:
            key: key
            isOk: response.ok
      .catch (error) ->
        console.error error
        toast.error "#{error}"

  formSchema = new SimpleSchema
    file:
      type: Object
      uniforms:
        component: FileInputField
    'file.original':
      type: Object
      blackbox: true
    'file.thumbnail':
      type: Object
      optional: true
      blackbox: true
    uploadAs:
      type: String
      allowedValues: uploadAsOptions
      uniforms: if uploadAsOptions.length is 1 then -> null
  
  formSchemaBridge = new SimpleSchema2Bridge formSchema

  onSubmit = (model) ->
    send {model, sourceName: tableDataOptions.sourceName}

  openModal = -> setFormModalIsOpen true
  
  # TODO implement logic for mayAdd
  mayAdd = true

  <>
    <FormModal
      schemaBridge={formSchemaBridge}
      onSubmit={onSubmit}
      model={freshModel}
      isOpen={formModalIsOpen}
    />
    <button
      className="primary icon"
      onClick={openModal} disabled={not mayAdd}
    >
      <FontAwesomeIcon icon={faPlus}/>
    </button>
  </>
