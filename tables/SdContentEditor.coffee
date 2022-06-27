import React from 'react'
import {MeteorTableDataHandler} from './MeteorTableDataHandler.coffee'
import {ContentEditor} from './ContentEditor.coffee'

export SdContentEditor = ({dataOptions, fileListDataOptions, customComponents = {}}) ->
  <MeteorTableDataHandler
    dataOptions={dataOptions}
    fileListDataOptions={fileListDataOptions}
    customComponents={customComponents}
    DisplayComponent={ContentEditor}
  />