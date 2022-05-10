import React, {useEffect, useState} from 'react'
import {meteorApply} from '../common/meteorApply.coffee'
import {toast} from 'react-toastify'
import {SdList} from '../tables/SdList.coffee'
import SimpleSchema from 'simpl-schema'
import SimpleSchema2Bridge from 'uniforms-bridge-simple-schema-2'
import {useCurrentUserIsInRole} from '../common/roleChecks.coffee'
import compact from 'lodash/compact'
import {FileInputField} from './FileInput.coffee'

SimpleSchema.extendOptions ['sdTable', 'uniforms']

send = ({model, sourceName}) ->
  console.log {original, thumbnail} = model.file
  file = thumbnail
  {name, size, type} = file
  console.log "filename: #{name}"
  meteorApply
    method: "#{sourceName}.requestUpload"
    data: {name, size, type}
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
    meteorApply
      method: "#{sourceName}.finishUpload"
      data:
        key: key
        statusText: response.statusText
  .catch (error) ->
    console.error error
    toast.error "#{error}"


ListItemContent  = ({rowData}) ->
  <div className="flex p-2 gap-2">
    <div className="h-[160px]">
      {
        if rowData.status is 'ok' and rowData.type?.startsWith?('image/') and rowData.size <= 100000
          <img className="max-h-full max-w-[100px]" src={rowData.url} alt={rowData.name} />
        else
          <div className="h-[100px] w-[100px] bg-gray-200 flex flex-row align-center content-center">
            <span>{rowData.type or '?'}</span>
          </div>
      }
    </div>

    <div>
      <div className="text-lg">{rowData.name}</div>
      <div className="text-sm">{rowData.size}</div>
      <div className="text-sm">{rowData.type}</div>

    </div>
    
  </div>

export FileList = ({dataOptions}) ->
  {tableDataOptions, roles} = dataOptions
  {getUserFileListRole, uploadUserFilesRole, getCommonFileListRole, uploadCommonFilesRole} = roles
  
  mayUploadCommonFiles = useCurrentUserIsInRole uploadCommonFilesRole
  mayUploadUserFiles = useCurrentUserIsInRole uploadUserFilesRole

  [files, setFiles] = useState []
  
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
      blackbox: true
    uploadAs:
      type: String
      allowedValues: compact [
        if mayUploadCommonFiles then 'public'
        if mayUploadUserFiles then 'private'
      ]
  formSchemaBridge = new SimpleSchema2Bridge formSchema

  onSubmit = (model) ->
    send {model, sourceName: tableDataOptions.sourceName}

  <SdList
    dataOptions={{tableDataOptions..., formSchemaBridge, onSubmit}}
    customComponents={{ListItemContent}}
  />