import React, {useEffect} from 'react'
import connectFieldPlus from './connectFieldPlus'

Link = ({value}) ->

  title = value?.title ? '[no title]'
  url = value?.url

  onClick = (event) ->
    event.preventDefault()
    event.stopPropagation()
    if url
      window.open url, '_blank'

  <div onClick={onClick}>
    {
      if url
        <a href={url} target="_blank">{title}</a>
      else
        <span>{title}</span>
    }
  </div>


export LinkField = connectFieldPlus ({value}) ->

  <div className="p-component p-card w-full p-4">
    <Link value={value} />
  </div>


export LinkTableField = ({row, columnKey, schemaBridge, onChangeField, measure, mayEdit}) ->
  <Link value={row[columnKey]} />
