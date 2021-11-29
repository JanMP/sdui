import React from 'react'
import {useTw} from '../config.coffee'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faTrash} from '@fortawesome/free-solid-svg-icons/faTrash'
import {MeteorMethodButton} from '../forms/MeteorMethodButton.coffee'

DefaultListItemContent = ({row}) ->
  tw = useTw()

  <div className={tw"bg-red-100"}>{JSON.stringify row, null, 2}</div>


export DefaultListItem = ({row, onDelete, ListItemContent = DefaultListItemContent}) ->
  
  tw = useTw()
  row ?= "no value"

  <div className={tw"p-2"}>
    <pre className={tw"p-2 rounded-lg shadow flex justify-between"}>
      <DefaultListItemContent row={row}/>
      <div className={tw"p-2 bg-blue-100"}>
        <MeteorMethodButton
          handler={-> onDelete id: row._id}
          icon={faTrash}
          confirmation="Soll der Eintrag wirklich gelöscht werden?"
        />
      </div>
    </pre>
  </div>