import React from 'react'
import connectFieldPlus from './connectFieldPlus.coffee'

export Thumbs = ({value, onChange, fontSize = '1rem'}) ->

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
    <i className="pi pi-thumbs-up cursor-pointer" style={{color: upColor, fontSize}} onClick={onUpClick}></i>
    <i className="ml-2 pi pi-thumbs-down cursor-pointer" style={{color: downColor, fontSize}} onClick={onDownClick}></i>
  </>


export ThumbsField = connectFieldPlus ({value, onChange}) ->

  <div className="w-full p-4 flex gap-4">
    <Thumbs value={value} onChange={onChange} fontSize={"2rem"}/>
  </div>

export ThumbsTableField = ({row, columnKey, schemaBridge, onChangeField, measure, mayEdit}) ->
  onChange = (d) ->
    onChangeField
      _id: row?._id ? row?.id
      changeData: "#{columnKey}": d

  <Thumbs value={row[columnKey]} onChange={onChange} />