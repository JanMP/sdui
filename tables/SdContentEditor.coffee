import React, {useEffect} from 'react'
import {MeteorTableDataHandler} from './MeteorTableDataHandler.coffee'
import {ContentEditor} from './ContentEditor.coffee'
import {SdTable} from './SdTable.coffee'
import {TableEditModalHandler} from './TableEditModalHandler.coffee'
import {DataList} from './DataList.coffee'

DisplayComponent = (tableOptions) ->

  # useEffect ->
  #   console.log 'DisplayComponent', tableOptions
  # , [tableOptions]

  <ContentEditor
    tableOptions={tableOptions}
    DisplayComponent={DataList}
  />

export SdContentEditor = ({dataOptions, customComponents = {}}) ->

  useEffect ->
    console.log 'SdContentEditor', dataOptions
  , [dataOptions]

  <MeteorTableDataHandler
    dataOptions={dataOptions}
    customComponents={customComponents}
    DisplayComponent={DisplayComponent}
  />