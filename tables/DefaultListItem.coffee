import React from 'react'
import {Button} from 'primereact/button'

DefaultListItemContent = ({rowData, measure}) ->
  <div className="flex-grow-1 py-1 px-2">{JSON.stringify rowData, null, 2}</div>


export DefaultListItem = ({
  rowData, index, canDelete, mayDelete, onDelete, onClick,
  ListItemContent = DefaultListItemContent, selectedRowId
  measure
}) ->
  
  rowData ?= {}
  id = rowData._id ? rowData.id

  isSelected = selectedRowId is id


  handleDeleteButtonClick = (e) ->
    e.stopPropagation()
    e.nativeEvent.stopImmediatePropagation()
    if id? and not rowData._disableDeleteForRow then onDelete {id}

  handleClick = ->
    if index? then onClick {rowData, index}

  isSelectedClass = if isSelected then ' border-primary border-2' else ''
  editableClass = if rowData._disableEditForRow then ' cursor-not-allowed' else ''

  
  <div className="p-1">
    <div
      className="p-component p-section flex flex-row gap-2 align-content-center
        #{isSelectedClass} #{editableClass}"
      onClick={handleClick}
    >
      <ListItemContent rowData={rowData} measure={measure}/>
      {
        if canDelete
          <div className="button-container">
            <Button
              icon="pi pi-delete-left"
              severity="danger"
              rounded text
              onClick={handleDeleteButtonClick}
              disabled={rowData._disableDeleteForRow or not mayDelete}
            />
          </div>
      }
    </div>
  </div>
