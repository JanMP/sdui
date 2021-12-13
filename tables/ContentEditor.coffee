import React, {useState, useEffect, useRef} from 'react'
import {DataList} from './DataList.coffee'
import {ErrorBoundary} from '../common/ErrorBoundary.coffee'
import {ConfirmationModal} from '../forms/ConfirmationModal.coffee'
import {useTw} from '../config.coffee'
import {Fill, Fixed, LeftResizable, Top, TopResizable, Custom, AnchorType} from 'react-spaces'
import AutoForm from '../forms/uniforms-custom/AutoForm.tsx'
import {MarkdownEditor} from '../markdown/MarkdownEditor.coffee'
import {MarkdownDisplay} from '../markdown/MarkdownDisplay.coffee'
import useSize from '@react-hook/size'
import _ from 'lodash'


export ContentEditor = (tableOptions) ->

  {
    sourceName
    listSchemaBridge, formSchemaBridge
    rows, totalRowCount, loadMoreRows, onRowClick,
    sortColumn, sortDirection, onChangeSort, useSort
    canSearch, search, onChangeSearch
    canAdd, onAdd
    canDelete, onDelete, deleteConfirmation
    canEdit, mayEdit, submit
    autoFormChildren, formDisabled, formReadOnly
    loadEditorData
    onChangeField,
    canExport, onExportTable
    mayExport
    isLoading,
    overscanRowCount
    customComponents
  } = tableOptions

  onAdd ?= ->
    openEditor {}

  loadEditorData ?= ({id}) -> console.log "loadEditorData id: #{id}"
  
  tw = useTw()

  [editorOpen, setEditorOpen] = useState false
  [model, setModel] = useState {}

  [confirmationModalOpen, setConfirmationModalOpen] = useState false
  [idForConfirmationModal, setIdForConfirmationModal] = useState ''

  formContainerRef = useRef null
  editorContainerRef = useRef null

  [formContainerWidth, formContainerHeight] = useSize formContainerWidth
  [editorContainerWidth, editorContainerHeight] = useSize editorContainerRef

  useEffect ->
    console.log {formContainerWidth, formContainerHeight, editorContainerWidth, editorContainerHeight}
  # , [formContainerWidth, formContainerHeight, editorContainerWidth, editorContainerHeight]

  useEffect ->
    console.log {formContainerRef, editorContainerRef}
  , [formContainerRef.current, editorContainerRef.current]

  contentKey =
    formSchemaBridge.schema._firstLevelSchemaKeys
    .find (key) -> formSchemaBridge.schema._schema[key]?.sdContent?.isContent
  

  setContent = (content) -> setModel (model) -> {model..., [contentKey]: content}
  
  
  handleOnDelete =
    unless canDelete
      -> console.error 'handleOnDelete has been called despite canDelete false'
    else
      ({id}) ->
        console.log 'handleOnDelete', {id, deleteConfirmation}
        if deleteConfirmation?
          setIdForConfirmationModal id
          setConfirmationModalOpen true
        else
          onDelete {id}

  openEditor = (formModel) ->
    setModel formModel
    setEditorOpen true


  submitAndClose =
    (d) -> submit?(d).then -> setEditorOpen false

  if canEdit
    onRowClick =
      ({rowData, index}) ->
        if formSchemaBridge is listSchemaBridge
          openEditor rows[index]
        else
          loadEditorData id: rowData._id
          ?.then openEditor

  
  <Fill>
    <ErrorBoundary>
      {
        if canDelete and deleteConfirmation?
          <ConfirmationModal
            isOpen={confirmationModalOpen}
            setIsOpen={setConfirmationModalOpen}
            text={deleteConfirmation}
            onConfirm={-> onDelete id: idForConfirmationModal}
          />
      }
      {
        if true
          <LeftResizable size="20%">
            <DataList
              {{
                sourceName
                listSchemaBridge,
                rows, totalRowCount, loadMoreRows, onRowClick,
                sortColumn, sortDirection, onChangeSort, useSort
                canSearch, search, onChangeSearch
                canAdd, onAdd
                canDelete, onDelete: handleOnDelete
                canEdit, mayEdit
                onChangeField,
                canExport, onExportTable
                mayExport
                isLoading
                overscanRowCount
                customComponents
              }...}
            />
          </LeftResizable>
      }
      {
        if mayEdit and editorOpen
          <LeftResizable size="40%">
            <TopResizable size={220}>
              <div ref={formContainerRef}>
                <AutoForm
                  schema={formSchemaBridge}
                  onChangeModel={setModel}
                  onSubmit={submitAndClose}
                  model={model}
                  children={autoFormChildren}
                  disabled={formDisabled}
                  validate="onChange"
                />
              </div>
            </TopResizable>
            <Fill>
              <div
                ref={editorContainerRef}
                className={tw"h-full"}
              >
                <MarkdownEditor
                  value={model?[contentKey]}
                  onChange={setContent}
                  editorWidth="100%"
                  editorHeight="100%"
                />
              </div>
            </Fill>
          </LeftResizable>
      }
      {
        if editorOpen
          <Fill>
            <MarkdownDisplay
              markdown={model?[contentKey]}
              contentClass="prose"
            />
          </Fill>
      }
    </ErrorBoundary>
  </Fill>
  