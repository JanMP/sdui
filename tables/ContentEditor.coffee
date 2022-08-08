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


###*
  @typedef {import("../interfaces").DataTableDisplayOptions} DataTableDisplayOptions
  ###
###*
  @type {
    (options: DataTableDisplayOptions) => React.FC
  }
  ###
export ContentEditor = (tableOptions) ->

  {
    sourceName
    listSchemaBridge, formSchemaBridge
    rows, totalRowCount, loadMoreRows, onRowClick,
    canSort, sortColumn, sortDirection, onChangeSort
    canSearch, search, onChangeSearch
    canUseQueryEditor, queryUiObject, onChangeQueryUiObject
    canAdd, mayAdd, onAdd
    canDelete, mayDelete, onDelete, deleteConfirmation
    canEdit, mayEdit, onSubmit
    autoFormChildren, formDisabled
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
    if hasChanged
      setIdForOverloadConfirmationModal null
      setOverloadConfirmationModalOpen true
    else
      newItem = await setupNewItem()
      openEditor newItem

  # TODO make optional (again) and i18n
  deleteConfirmation ?= "Soll der Eintrag wirklich gelöscht werden?"

  loadEditorData ?= ({id}) -> console.log "stump for loadEditorData id: #{id}"

  [editorOpen, setEditorOpen] = useState false
  [loadedModel, setLoadedModel] = useState {}
  [changedModel, setChangedModel] = useState {}
  [isValid, setIsValid] = useState false
  [selectedRowId, setSelectedRowId] = useState "fnord"

  [deleteConfirmationModalOpen, setDeleteConfirmationModalOpen] = useState false
  [idForDeleteConfirmationModal, setIdForDeleteConfirmationModal] = useState ''
  
  [overloadConfirmationModalOpen, setOverloadConfirmationModalOpen] = useState false
  [idForOverloadConfirmationModal, setIdForOverloadConfirmationModal] = useState null

  hasChanged = not _.isEqual changedModel, loadedModel

  contentKey =
    formSchemaBridge.schema._firstLevelSchemaKeys
    .find (key) -> formSchemaBridge.schema._schema[key]?.sdContent?.isContent
  
  setContent = (content) -> setChangedModel (previousModel) -> {previousModel..., [contentKey]: content}

  deleteAndCloseEditor = ({id}) ->
    onDelete {id}
    setEditorOpen false

  handleOnDelete =
    unless canDelete
      -> console.error 'handleOnDelete has been called despite canDelete false'
    else
      ({id}) ->
        if deleteConfirmation?
          setIdForDeleteConfirmationModal id
          setDeleteConfirmationModalOpen true
        else
          deleteAndCloseEditor {id}

  openEditor = (formModel) ->
    setLoadedModel formModel
    setChangedModel formModel
    setEditorOpen true
  
  onValidate = (model, error) ->
    setIsValid not error?
    error

  onReset = ->
    setChangedModel loadedModel

  handleSubmit =
    (model) ->
      onSubmit?(model)
      .then (result) ->
        if (id = result?.insertedId ? model._id)?
          setSelectedRowId id
          loadEditorData {id}
          ?.then openEditor


  onConfirmOverload = ->
    console.log id = idForOverloadConfirmationModal
    if id?
      setSelectedRowId id
      loadEditorData {id}
        ?.then openEditor
    else
      newItem = await setupNewItem()
      openEditor newItem

  if canEdit
    onRowClick =
      ({rowData, index}) ->
        return if rowData._id is loadedModel._id
        if hasChanged
          setIdForOverloadConfirmationModal rowData._id
          setOverloadConfirmationModalOpen true
        else
          setSelectedRowId rowData._id
          loadEditorData id: rowData._id
          ?.then openEditor

  
  <Fill>
    <ErrorBoundary>
      <ConfirmationModal
        isOpen={overloadConfirmationModalOpen}
        setIsOpen={setOverloadConfirmationModalOpen}
        text="Sie haben ungesicherte Änderungen. Wollen sie die Änderungen Verwerfen?"
        onConfirm={onConfirmOverload}
      />
      {
        if canDelete and deleteConfirmation?
          <ConfirmationModal
            isOpen={deleteConfirmationModalOpen}
            setIsOpen={setDeleteConfirmationModalOpen}
            text={deleteConfirmation}
            onConfirm={-> deleteAndCloseEditor id: idForDeleteConfirmationModal}
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
            canUseQueryEditor, queryUiObject, onChangeQueryUiObject
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
                    value={changedModel?[contentKey]}
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
                  model={changedModel}
                  onChangeModel={setChangedModel}
                  onValidate={onValidate}
                  children={autoFormChildren}
                  disabled={formDisabled}
                  validate="onChange"
                  submitField={-> null}
                />
                <div className="p-2">
                  <ActionButton
                    onAction={onReset}
                    className="button danger"
                    label="Zurücksetzen"
                    disabled={not hasChanged}
                  />
                  <ActionButton
                    onAction={-> handleSubmit changedModel}
                    className="button primary ml-2"
                    label="Speichern"
                    disabled={(not hasChanged) or (not isValid)}
                  />
                </div>
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
                    <Preview content={changedModel}/>
                  else
                    <MarkdownDisplay
                      markdown={changedModel?[contentKey]}
                      contentClass="prose"
                    />
                }
              </ErrorBoundary>
            </Fill>
            {
              if RelatedDataPane?
                <BottomResizable size="50%" scrollable>
                  <RelatedDataPane model={changedModel}/>
                </BottomResizable>
            }
          </Fill>
      }
    </ErrorBoundary>
  </Fill>
  