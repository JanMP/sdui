import React from 'react'
import {MeteorTableDataHandler} from './MeteorTableDataHandler.coffee'
import {DataList} from './DataList.coffee'
import {TableEditModalHandler} from './TableEditModalHandler.coffee'

export DisplayComponent = (tableOptions) ->
  <TableEditModalHandler
    tableOptions={tableOptions}
    DisplayComponent={DataList}
  />

export SdList = ({dataOptions, customComponents}) ->
  <MeteorTableDataHandler
    dataOptions={dataOptions}
    DisplayComponent={DisplayComponent}
    customComponents={customComponents}
  />