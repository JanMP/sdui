import React, {useState, useEffect, useRef} from 'react'
import {DataList} from './DataList.coffee'
import {ErrorBoundary} from '../common/ErrorBoundary.coffee'
import {ConfirmationModal} from '../forms/ConfirmationModal.coffee'
import {Splitter, SplitterPanel} from 'primereact/splitter'
import {ScrollPanel} from 'primereact/scrollpanel'
import {AutoForm} from '../forms/uniforms-custom/select-implementation'
import {SdEditor} from '../editor/SdEditor.coffee'
import {MarkdownDisplay} from '../markdown/MarkdownDisplay.coffee'
import {ActionButton} from '../forms/ActionButton.coffee'
import useSize from '@react-hook/size'
import _ from 'lodash'
import * as types from '../typeDeclarations'


PanelHeader = ({text}) ->
  <div className="w-full text-surface-800 surface-200 p-1">
   {text}
  </div>

###*
  @typedef {import("../interfaces").DataTableDisplayOptions} DataTableDisplayOptions
  ###
###*
  @type {
    (options: {
      tableOptions: DataTableDisplayOptions
      DisplayComponent: {(options: DataTableDisplayOptions): React.FC}
    }) => React.FC
  }
  ###
export ContentEditor = ({tableOptions}) ->
  {
  sourceName
  listSchema, formSchema,
  rows, loadMoreRows, onRowClick,
  canSort, sortColumn, sortDirection, onChangeSort
  canSearch, search, onChangeSearch
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

  {Preview, RelatedDataPane} = customComponents ? {}

  Preview ?= ({content}) ->
    <ScrollPanel className="h-full w-full p-2">
      <MarkdownDisplay
        markdown={content?[contentKey]}
        contentClass="prose"
      />
    </ScrollPanel>

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
    formSchema.firstLevelSchemaKeys
    .find (key) -> formSchema._schema.properties[key]?.sdContent?.isContent
  
  setContent = (content) -> setChangedModel (previousModel) -> {previousModel..., [contentKey]: content}

  deleteAndCloseEditor = ({id}) ->
    onDelete {id}
    setEditorOpen false

  setAndLogChangedModel = (model) ->
    setChangedModel model
    console.log {model}
    
  useEffect ->
    console.log {loadedModel, changedModel, hasChanged}
  , [loadedModel, changedModel, hasChanged]

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
    id = idForOverloadConfirmationModal
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

  formPanelContent =
    <ScrollPanel className="p-2 w-full overflow-none" >
      <AutoForm
        schema={formSchema.bridge}
        model={changedModel}
        onChangeModel={setChangedModel}
        onValidate={onValidate}
        children={autoFormChildren}
        disabled={formDisabled}
        validate="onChange"
        submitField={-> null}
      />
      <div className="mt-4 mr-2 flex justify-content-end gap-2">
        <ActionButton
          onAction={onReset}
          className="p-button-warning"
          label="Zurücksetzen"
          disabled={not hasChanged}
        />
        <ActionButton
          onAction={-> handleSubmit changedModel}
          className="p-button-primary"
          label="Speichern"
          disabled={(not hasChanged) or (not isValid)}
        />
      </div>
    </ScrollPanel>

  <div className="p-component h-full w-full overflow-hidden">
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
      <Splitter gutterSize={8} className="h-full max-h-full">
        <SplitterPanel className="max-h-full h-full select-none p-2" size={10}>
          <DataList
            {{
              sourceName
              listSchema,
              rows, loadMoreRows, onRowClick,
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
        </SplitterPanel>
        <SplitterPanel className="max-h-full h-full select-none p-2">
          {
            if mayEdit and editorOpen
              <Splitter gutterSize={8} className="select-none h-full">
                <SplitterPanel className="pr-2 max-h-full h-full">
                  <Splitter gutterSize={8} layout="vertical"  className="min-h-0 max-h-full h-full">
                    <SplitterPanel size={20} className="min-h-0 h-full max-h-full pb-2">
                      <div className="h-full w-full flex flex-column overflow-hidden">
                        <PanelHeader text="Markdown/HTML" />
                        <SdEditor
                          value={changedModel[contentKey]}
                          onChange={setContent}
                        />
                      </div>
                    </SplitterPanel>
                    <SplitterPanel size={80} className ="min-h-0 max-h-full h-full w-full">
                      {formPanelContent}
                    </SplitterPanel>
                  </Splitter>
                </SplitterPanel>
                <SplitterPanel className="flex flex-column">
                  {
                    if RelatedDataPane?
                      <Splitter gutterSize={8} layout="vertical" className="h-full">
                        <SplitterPanel className="min-h-0 max-h-full">
                          <PanelHeader text="Preview" />
                          <Preview content={changedModel}/>
                        </SplitterPanel>
                        <SplitterPanel className="min-h-0 max-h-full">
                          <div className="h-full w-full flex flex-column overflow-hidden">
                            <PanelHeader text="Data" />
                            <RelatedDataPane model={changedModel}/>
                          </div>
                        </SplitterPanel>
                      </Splitter>
                    else
                      <div className="h-full w-full flex flex-column overflow-hidden">
                        <PanelHeader text="Preview" />
                        <Preview content={changedModel}/>
                      </div>
                  }
                </SplitterPanel>
              </Splitter>
          }
        </SplitterPanel>
      </Splitter>
    </ErrorBoundary>
  </div>