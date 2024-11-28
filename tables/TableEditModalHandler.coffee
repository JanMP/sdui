import React, {useState, useEffect, useRef} from 'react'
# import {Button, Icon, Modal} from 'semantic-ui-react'
import {DataTable} from './DataTable.coffee'
import {ErrorBoundary} from '../common/ErrorBoundary.coffee'
import {ConfirmationModal} from '../forms/ConfirmationModal.coffee'
import {FormModal} from '../forms/FormModal.coffee'

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
export TableEditModalHandler = ({tableOptions, DisplayComponent}) ->
  {
    sourceName
    listSchema, formSchema
    rows, loadMoreRows, onRowClick,
    canSort, sortColumn, sortDirection, onChangeSort
    canSearch, search, onChangeSearch
    canAdd, mayAdd, onAdd
    canDelete, mayDelete, onDelete
    canEdit, mayEdit, onSubmit
    autoFormChildren, formDisabled, formReadOnly
    loadEditorData
    onChangeField,
    canExport, onExportTable
    mayExport
    setupNewItem
    isLoading,
    overscanRowCount
    customComponents
  } = tableOptions

  onRowClick ?= ({rowData, index}) -> console.log 'stub for onRowClick', {rowData, index}
  onAdd ?= ->
    newItem = await setupNewItem()
    openModal newItem

  loadEditorData ?= ({id}) -> console.log "stub for loadEditorData id: #{id}"

  [modalOpen, setModalOpen] = useState false
  [model, setModel] = useState {}

  [confirmationModalOpen, setConfirmationModalOpen] = useState false
  [idForConfirmationModal, setIdForConfirmationModal] = useState ''

  # TODO make optional (again) and i18n
  deleteConfirmation = "Soll der Eintrag wirklich gelöscht werden?"

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

  openModal = (formModel) ->
    setModel formModel
    setModalOpen true


  submitAndClose = (d) -> onSubmit?(d).then -> setModalOpen false

  if canEdit
    onRowClick =
      ({rowData, index}) ->
        return if rowData._disableEditForRow
        if formSchema is listSchema
          openModal rows[index]
        else
          loadEditorData id: rowData._id
          ?.then openModal

  <>
    {
      if mayEdit
        <FormModal
          schemaBridge={formSchema.bridge}
          onSubmit={submitAndClose}
          model={model}
          isOpen={modalOpen}
          onRequestClose={-> setModalOpen false}
          children={autoFormChildren}
          disabled={formDisabled}
          readOnly={formReadOnly}
        />
    }
    {
      if canDelete
        <ConfirmationModal
          isOpen={confirmationModalOpen}
          setIsOpen={setConfirmationModalOpen}
          text={deleteConfirmation}
          onConfirm={-> onDelete id: idForConfirmationModal}
        />
    }
    <ErrorBoundary>
      <DisplayComponent
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
          setupNewItem
        }...}
      />
    </ErrorBoundary>
  </>