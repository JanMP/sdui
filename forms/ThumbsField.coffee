import React, {useEffect} from 'react'
import connectFieldWithLabel from './connectFieldWithLabel'

Thumbs = ({value, onChange}) ->

  upColor = if value is 'up' then 'green' else 'grey'
  downColor = if value is 'down' then 'red' else 'grey'

  onUpClick = (event) ->
    event.preventDefault()
    event.stopPropagation()
    if value is 'up'
      onChange null
    else
      onChange 'up'

  onDownClick = (event) ->
    event.preventDefault()
    event.stopPropagation()
    if value is 'down'
      onChange null
    else
      onChange 'down'


  <>
    <i className="pi pi-thumbs-up" style={color: upColor} onClick={onUpClick}></i>
    <i className="ml-2 pi pi-thumbs-down" style={color: downColor} onClick={onDownClick}></i>
  </>


export ThumbsField = connectFieldWithLabel ({value, onChange}) ->

  <div className="p-component p-card w-full p-4">
    <Thumbs value={value} onChange={onChange}/>
  </div>

export ThumbsTableField = ({row, columnKey, schemaBridge, onChangeField, measure, mayEdit}) ->
  onChange = (d) ->
    onChangeField
      _id: row?._id ? row?.id
      changeData: "#{columnKey}": d

  <Thumbs value={row[columnKey]} onChange={onChange} />