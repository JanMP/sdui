import React from 'react'
import {MeteorTableDataHandler} from './MeteorTableDataHandler.coffee'
import {ContentEditor} from './ContentEditor.coffee'

export SdContentEditor = ({dataOptions, customComponents = {}}) ->
  <MeteorTableDataHandler
    dataOptions={dataOptions}
    customComponents={customComponents}
    DisplayComponent={ContentEditor}
  />