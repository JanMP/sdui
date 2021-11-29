import React from 'react'
import {MeteorTableDataHandler} from './MeteorTableDataHandler.coffee'
import {EditableDataList} from './EditableDataList.coffee'

export SdContentEditor = ->
  <MeteorTableDataHandler
    dataOptions={dataOptions}
    DisplayComponent={ContentEditor}
    customComponents={customComponents}
  />