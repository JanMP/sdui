import React, {useEffect, useState} from 'react'
import {meteorApply} from '../common/meteorApply.coffee'
import {useCurrentUserIsInRole} from '../common/roleChecks.coffee'
import SimpleSchema from 'simpl-schema'
import SimpleSchema2Bridge from 'uniforms-bridge-simple-schema-2'
import {FontAwesomeIcon} from '@fortAwesome/react-fontawesome'
import {faPlus} from '@fortawesome/free-solid-svg-icons/faPlus'
import {toast} from 'react-toastify'
import {FileInputField} from './FileInput.coffee'
import {FormModal} from '../forms/FormModal.coffee'
import compact from 'lodash/compact'
import pick from 'lodash/pick'
import axios from 'axios'
import Modal from 'react-modal'
import {ReactiveVar} from 'meteor/reactive-var'
import {useTracker} from 'meteor/react-meteor-data'


SimpleSchema.extendOptions ['sdTable', 'uniforms']

# TODO there are redraws that keep resetting our local state, so for now
# we will use meteor reactive vars as a workaround
progressRV = new ReactiveVar null
progressModalTextRV = new ReactiveVar null

pickFileMetaData = (file) -> pick file, ["name", "size", "type"]

export FileUploadButton = ({dataOptions}) ->
  
  {tableDataOptions, roles} = dataOptions
  {uploadUserFilesRole, uploadCommonFilesRole} = roles

  [formModalIsOpen, setFormModalIsOpen] = useState false

  progress = useTracker -> progressRV.get()
  progressModalText = useTracker -> progressModalTextRV.get()

  mayUploadCommonFiles = useCurrentUserIsInRole uploadCommonFilesRole
  mayUploadUserFiles = useCurrentUserIsInRole uploadUserFilesRole

  allowedListingScopes = compact [
    if mayUploadCommonFiles then 'public'
    if mayUploadUserFiles then 'private'
  ]

  mayAdd = allowedListingScopes.length > 0

  freshModel =
    listingScope: allowedListingScopes[0]

  send = ({model, sourceName}) ->
    progressModalTextRV.set 'preparing upload'
    progressRV.set null
    methodData = {
      model...
      file:
        file: pickFileMetaData model.file.file
        thumbnail: pickFileMetaData model.file.thumbnail
    }
    processData = {}
    meteorApply
      method: "#{sourceName}.requestUpload"
      data: methodData
    .then (result) ->
      processData = result
      progressModalTextRV.set 'uploading file'
      response =
        await axios
          url: processData.fileUploadUrl,
          method: 'PUT'
          headers:
            'Content-Type': model.file.file.type
            'x-amz-acl': 'public-read'
          data: model.file.file
          onUploadProgress: (p) ->
            progressRV.set p.loaded / p.total
      throw new Error 'could not upload file' unless  response.status is 200
    .then ->
      return unless processData.thumbnailUploadUrl?
      progressModalTextRV.set 'uploading thumbnail'
      response =
        await axios
          url: processData.thumbnailUploadUrl,
          method: 'PUT'
          headers:
            'Content-Type': model.file.thumbnail.type
            'x-amz-acl': 'public-read'
          data: model.file.thumbnail
          onUploadProgress: (p) ->
            progressRV.set p.loaded / p.total
      throw new Error 'could not upload thumbnail' unless response.status is 200
    .then ->
      progressModalTextRV.set 'finishing upload'
      progressRV.set null
      meteorApply
        method: "#{sourceName}.finishUpload"
        data:
          key: processData.fileKey
          isOK: true
    .then ->
      progressModalTextRV.set null
    .catch (error) ->
      progressModalTextRV.set null
      console.error error
      toast.error "#{error}"

  formSchema = new SimpleSchema
    file:
      type: Object
      uniforms:
        component: FileInputField
    'file.file':
      type: Object
      blackbox: true
    'file.thumbnail':
      type: Object
      optional: true
      blackbox: true
    label:
      label: 'Alt-Name/Link-Text'
      type: String
      optional: true
    listingScope:
      type: String
      label: 'Auflisten unter'
      allowedValues: ['public', 'private']
      uniforms:
        disabled: if allowedListingScopes.length is 1 then true else false
  
  formSchemaBridge = new SimpleSchema2Bridge formSchema

  onSubmit = (model) ->
    send {model, sourceName: tableDataOptions.sourceName}

  openModal = -> setFormModalIsOpen true

  <div>
    <FormModal
      schemaBridge={formSchemaBridge}
      onRequestClose={-> setFormModalIsOpen false}
      onSubmit={onSubmit}
      model={freshModel}
      isOpen={formModalIsOpen}
    />
    <Modal
      isOpen={progressModalText?}
      onRequestClose={->}
      className="modal"
      overlayClassName="overlay"
      shouldFocusAfterRender={false}
    >
      <div>
        <div>{progressModalText}</div>
          <div className="w-full h-[2rem] bg-secondary-200">
            {if progress? then <div className="bg-primary-300 h-full" style={width: "#{progress * 100}%"}></div>}
          </div>
      </div>
    </Modal>
    <button
      className="primary icon"
      onClick={openModal} disabled={not mayAdd}
    >
      <FontAwesomeIcon icon={faPlus}/>
    </button>
  </div>
