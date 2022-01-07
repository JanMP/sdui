import React, {useState, useEffect, useRef} from 'react'
import {DataList} from './DataList.coffee'
import {ErrorBoundary} from '../common/ErrorBoundary.coffee'
import {ConfirmationModal} from '../forms/ConfirmationModal.coffee'
import {useTw} from '../config.coffee'
import {Fill, LeftResizable, TopResizable, Top} from 'react-spaces'
import {AutoForm} from 'uniforms-custom'
import {MarkdownEditor} from '../markdown/MarkdownEditor.coffee'
import {MarkdownDisplay} from '../markdown/MarkdownDisplay.coffee'
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

  {Preview} = customComponents ? {}

  onAdd ?= ->
    openEditor {}

  loadEditorData ?= ({id}) -> console.log "loadEditorData id: #{id}"

  [editorOpen, setEditorOpen] = useState false
  [model, setModel] = useState {}

  [confirmationModalOpen, setConfirmationModalOpen] = useState false
  [idForConfirmationModal, setIdForConfirmationModal] = useState ''

  editorInstance = useRef()

  contentKey =
    formSchemaBridge.schema._firstLevelSchemaKeys
    .find (key) -> formSchemaBridge.schema._schema[key]?.sdContent?.isContent
  
  setContent = (content) -> setModel (currentModel) -> {currentModel..., [contentKey]: content}
  
  handleOnDelete =
    unless canDelete
      -> console.error 'handleOnDelete has been called despite canDelete false'
    else
      ({id}) ->
        if deleteConfirmation?
          setIdForConfirmationModal id
          setConfirmationModalOpen true
        else
          onDelete {id}

  openEditor = (formModel) ->
    setModel formModel
    setEditorOpen true


  submitAndClose =
    (d) ->
      console.log 'submitAndClose', d
      submit?(d).then -> setEditorOpen false

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
          <LeftResizable size="50%">
            <TopResizable size="20%" onResizeEnd={-> editorInstance?.current?.editor?.resize()} >
            <Top size="2rem" className="text-sm bg-stone-200 p-2">Content</Top>
              <Fill>
                <ErrorBoundary>
                  <MarkdownEditor
                    instance={editorInstance}
                    value={model?[contentKey]}
                    onChange={setContent}
                  />
                </ErrorBoundary>
              </Fill>
            </TopResizable>
            <Fill>
              <Top size="2rem" className="text-sm bg-stone-200 p-2">Data</Top>
              <Fill scrollable>
                <AutoForm
                  schema={formSchemaBridge}
                  onSubmit={submitAndClose}
                  model={model}
                  onChangeModel={setModel}
                  children={autoFormChildren}
                  disabled={formDisabled}
                  validate="onChange"
                />
              </Fill>
            </Fill>
          </LeftResizable>
      }
      {
        if editorOpen
          <Fill>
            <Top size="2rem" className="text-sm bg-stone-200 p-2">Preview</Top>
            <Fill scrollable>
              <ErrorBoundary>
                {
                  if Preview?
                    <Preview content={model}/>
                  else
                    <MarkdownDisplay
                      markdown={model?[contentKey]}
                      contentClass="prose"
                    />
                }
              </ErrorBoundary>
            </Fill>
          </Fill>
      }
    </ErrorBoundary>
  </Fill>
  