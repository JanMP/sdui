import React from 'react'
import {useTw} from '../config.coffee'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faTrash} from '@fortAwesome/free-solid-svg-icons/faTrash'

DefaultListItemContent = ({rowData}) ->
  tw = useTw()

  <div className={tw"bg-red-100"}>{JSON.stringify rowData, null, 2}</div>


export DefaultListItem = ({
  rowData, index, canDelete, onDelete, onClick,
  ListItemContent = DefaultListItemContent, selectedRowId
}) ->
  
  tw = useTw()
  rowData ?= {}
  id = rowData._id ? rowData.id

  isSelected = selectedRowId is id


  handleDeleteButtonClick = (e) ->
    e.stopPropagation()
    e.nativeEvent.stopImmediatePropagation()
    if id? and not rowData._disableDeleteForRow then onDelete {id}

  handleClick = ->
    if index? then onClick {rowData, index}

  isSelectedClass = if isSelected then ' bg-secondary-100' else ''
  editableClass = if rowData._disableEditForRow then ' not-editable-row' else 'editable-row'

  <div className={tw "p-1 shadow flex justify-between#{isSelectedClass} #{editableClass}"} onClick={handleClick}>
    <ListItemContent rowData={rowData}/>
    {
      if canDelete
        <div className={tw"p-2"}>
          <button
            className="icon danger"
            onClick={handleDeleteButtonClick}
            disabled={rowData._disableDeleteForRow}
          >
            <FontAwesomeIcon icon={faTrash}/>
          </button>
        </div>
    }
  </div>