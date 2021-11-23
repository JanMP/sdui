import React from 'react'
import {useTw} from '../config.coffee'

export DefaultListItem = ({row}) ->
  tw = useTw()
  row ?= "no value for row given"

  <div className="p-2">
    <pre className={tw"p-2 rounded-lg bg-secondary text-primary"}>
      {JSON.stringify row, null, 2}
    </pre>
  </div>