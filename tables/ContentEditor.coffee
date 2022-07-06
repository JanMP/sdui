import React, {useState, useEffect, useRef} from 'react'
import {DataList} from './DataList.coffee'
import {ErrorBoundary} from '../common/ErrorBoundary.coffee'
import {ConfirmationModal} from '../forms/ConfirmationModal.coffee'
import {Fill, LeftResizable, BottomResizable, TopResizable, Top, Bottom} from 'react-spaces'
import {AutoForm} from '../forms/uniforms-custom/select-implementation'
import {SdEditor} from '../editor/SdEditor.coffee'
import {MarkdownDisplay} from '../markdown/MarkdownDisplay.coffee'
import {ActionButton} from '../forms/ActionButton.coffee'
import {faVial} from '@fortawesome/free-solid-svg-icons/faVial'
import {faFolderOpen} from '@fortawesome/free-solid-svg-icons/faFolderOpen'
import {faFolderClosed} from '@fortawesome/free-solid-svg-icons/faFolderClosed'
import {FileSelect} from '../files/FileSelect.coffee'
import _ from 'lodash'


export ContentEditor = (tableOptions) ->

  {
    sourceName
    listSchemaBridge, formSchemaBridge
    rows, totalRowCount, loadMoreRows, onRowClick,
    canSort, sortColumn, sortDirection, onChangeSort
    canSearch, search, onChangeSearch
    canAdd, mayAdd, onAdd
    canDelete, mayDelete, onDelete, deleteConfirmation
    canEdit, mayEdit, onSubmit
    autoFormChildren, formDisabled, formReadOnly
    loadEditorData
    onChangeField,
    canExport, onExportTable
    mayExport
    isLoading,
    overscanRowCount
    customComponents
    setupNewItem
  } = tableOptions

  {Preview, RelatedDataPane, FilePane} = customComponents ? {}

  onAdd ?= ->
    newItem = await setupNewItem()
    openEditor newItem

  # TODO make optional (again) and i18n
  deleteConfirmation ?= "Soll der Eintrag wirklich gelöscht werden?"

  loadEditorData ?= ({id}) -> console.log "loadEditorData id: #{id}"

  [editorOpen, setEditorOpen] = useState false
  [model, setModel] = useState {}
  [selectedRowId, setSelectedRowId] = useState "fnord"

  [confirmationModalOpen, setConfirmationModalOpen] = useState false
  [idForConfirmationModal, setIdForConfirmationModal] = useState ''

  [filePaneOpen, setFilePaneOpen] = useState false
  toggleFilePaneOpen = -> setFilePaneOpen (x) -> not x

  editorInstance = useRef()

  contentKey =
    formSchemaBridge.schema._firstLevelSchemaKeys
    .find (key) -> formSchemaBridge.schema._schema[key]?.sdContent?.isContent
  
  setContent = (content) -> setModel (currentModel) -> {currentModel..., [contentKey]: content}

  deleteAndCloseEditor = ({id}) ->
    onDelete {id}
    setEditorOpen false

  handleOnDelete =
    unless canDelete
      -> console.error 'handleOnDelete has been called despite canDelete false'
    else
      ({id}) ->
        if deleteConfirmation?
          setIdForConfirmationModal id
          setConfirmationModalOpen true
        else
          deleteAndCloseEditor {id}

  openEditor = (formModel) ->
    setModel formModel
    setEditorOpen true

  handleSubmit =
    (model) ->
      onSubmit?(model)
      .then (result) ->
        if (id = result?.insertedId)?
          setSelectedRowId id
          loadEditorData {id}
          ?.then openEditor

  if canEdit
    onRowClick =
      ({rowData, index}) ->
        setSelectedRowId rowData?._id
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
            onConfirm={-> deleteAndCloseEditor id: idForConfirmationModal}
          />
      }
      <LeftResizable size="25%">
        <DataList
          {{
            sourceName
            listSchemaBridge,
            rows, totalRowCount, loadMoreRows, onRowClick,
            canSort, sortColumn, sortDirection, onChangeSort
            canSearch, search, onChangeSearch
            canAdd, mayAdd, onAdd
            canDelete, mayDelete, onDelete: handleOnDelete
            canEdit, mayEdit
            onChangeField,
            canExport, onExportTable
            mayExport
            isLoading
            overscanRowCount
            customComponents
            selectedRowId
          }...}
        />
      </LeftResizable>
      {
        if mayEdit and editorOpen
          <LeftResizable size="50%">
            <TopResizable size="20%">
              <Top size="2rem" className="text-sm bg-secondary-200 p-2" allowOverflow>Content</Top>
              <Fill allowOverflow>
                <ErrorBoundary>
                  <SdEditor
                    value={model?[contentKey]}
                    onChange={setContent}
                  />
                </ErrorBoundary>
              </Fill>
            </TopResizable>
            <Fill>
              <Top size="2rem" className="text-sm bg-secondary-200 p-2">Data</Top>
              <Fill scrollable>
                <AutoForm
                  schema={formSchemaBridge}
                  onSubmit={handleSubmit}
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
            <Top size="2rem" className="text-sm bg-secondary-200 p-2">Preview</Top>
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
            {
              if RelatedDataPane?
                <BottomResizable size="50%" scrollable>
                  <RelatedDataPane model={model}/>
                </BottomResizable>
            }
          </Fill>
      }
    </ErrorBoundary>
  </Fill>
  