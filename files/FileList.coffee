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
      meteorApply
        method: "#{sourceName}.finishUpload"
        data:
          key: key
          isOk: response.ok
    .catch (error) ->
      console.error error
      toast.error "#{error}"


ListItemContent  = ({rowData}) ->
  <div className="flex p-2 gap-4 overflow-hidden">
    <div>
      {
        if rowData.thumbnailUrl? and rowData.thumbnailStatus is 'ok'
          <div className="h-[100px] w-[150px] flex justify-center">
            <img className="shadow" src={rowData.thumbnailUrl} alt={rowData.name} />
          </div>
        else
          <div className="h-[100px] w-[150px] bg-gray-200 flex flex-row align-center content-center shadow">
            <div>{rowData.type or '?'}</div>
          </div>
      }
    </div>

    <div>
      <a href={rowData.url}>
        <span>{rowData.name}</span>
      </a>
      <div className="text-sm">Size: {rowData.size}</div>
      <div className="text-sm">Type: {rowData.type}</div>
      <div className="text-sm">
        {if rowData.isCommon then 'public' else 'private'}
      </div>
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
      optional: true
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