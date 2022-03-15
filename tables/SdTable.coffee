import React from 'react'
import {MeteorTableDataHandler} from './MeteorTableDataHandler.coffee'
import {TableEditModalHandler} from './TableEditModalHandler.coffee'
import {DataTable} from './DataTable.coffee'

DisplayComponent = (tableOptions) ->
  <TableEditModalHandler
    tableOptions={tableOptions}
    DisplayComponent={DataTable}
  />

export SdTable = ({dataOptions, customComponents}) ->
  <MeteorTableDataHandler
    dataOptions={dataOptions}
    DisplayComponent={DisplayComponent}
    customComponents={customComponents}
  />