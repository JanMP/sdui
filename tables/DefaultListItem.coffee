import React from 'react'
import {useTw} from '../config.coffee'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faTrash} from '@fortawesome/free-solid-svg-icons/faTrash'
import {MeteorMethodButton} from '../forms/MeteorMethodButton.coffee'

export DefaultListItem = ({row, onDelete}) ->
  tw = useTw()
  row ?= "no value for row given"

  <div className={tw"p-2"}>
    <pre className={tw"p-2 rounded-lg shadow flex justify-between"}>
      <div>{JSON.stringify row, null, 2}</div>
      <div className={tw"p-2"}>
        <MeteorMethodButton
          handler={-> onDelete id: row._id}
          icon={faTrash}
          confirmation="Soll der Eintrag wirklich gelöscht werden?"
        />
      </div>
    </pre>
  </div>