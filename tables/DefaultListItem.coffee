import React from 'react'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faTrash} from '@fortawesome/free-solid-svg-icons/faTrash'

DefaultListItemContent = ({rowData, measure}) ->
  <div className="default-list-item__default-content">{JSON.stringify rowData, null, 2}</div>


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

  isSelectedClass = if isSelected then ' default-list-item--selected' else ''
  editableClass = if rowData._disableEditForRow then ' default-list-item--not-editable' else ''

  <div className="default-list-item | #{isSelectedClass} #{editableClass}" onClick={handleClick}>
    <ListItemContent rowData={rowData} measure={measure}/>
    {
      if canDelete
        <div className="button-container">
          <button
            className="icon danger"
            onClick={handleDeleteButtonClick}
            disabled={rowData._disableDeleteForRow or not mayDelete}
          >
            <FontAwesomeIcon icon={faTrash}/>
          </button>
        </div>
    }
  </div>