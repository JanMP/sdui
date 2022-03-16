import React from 'react'
import {MeteorTableDataHandler} from './MeteorTableDataHandler.coffee'
import {TableEditModalHandler} from './TableEditModalHandler.coffee'
import {DataTable} from './DataTable.coffee'

###*
  @typedef {import("../interfaces").DataTableOptions} DataTableOptions
  ###
DisplayComponent = (tableOptions) ->
  <TableEditModalHandler
    tableOptions={tableOptions}
    DisplayComponent={DataTable}
  />

###*
  @type {({dataOptions, customComponents}: {dataOptions: DataTableOptions, customComponents: any}) => JSX.Element }
  ###
export SdTable = ({dataOptions, customComponents}) ->
  <MeteorTableDataHandler
    dataOptions={dataOptions}
    DisplayComponent={DisplayComponent}
    customComponents={customComponents}
  />