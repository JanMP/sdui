import React from 'react'
import {useTw} from '../config.coffee'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faTrash} from '@fortawesome/free-solid-svg-icons/faTrash'

DefaultListItemContent = ({rowData}) ->
  tw = useTw()

  <div className={tw"bg-red-100"}>{JSON.stringify rowData, null, 2}</div>


export DefaultListItem = ({rowData, index, onDelete, onClick, ListItemContent = DefaultListItemContent}) ->
  
  tw = useTw()
  rowData ?= {}
  id = rowData._id ? rowData.id

  handleDeleteButtonClick = (e) ->
    e.stopPropagation()
    e.nativeEvent.stopImmediatePropagation()
    if id? then onDelete {id}

  handleClick = ->
    if index? then onClick {rowData, index}

  <div className={tw"p-2"}>
    <pre className={tw"p-2 rounded-lg shadow flex justify-between"} onClick={handleClick}>
      <DefaultListItemContent rowData={rowData}/>
      <div className={tw"p-2 bg-blue-100"}>
        <button
          onClick={handleDeleteButtonClick}
        >
          <FontAwesomeIcon icon={faTrash}/>
        </button>
      </div>
    </pre>
  </div>