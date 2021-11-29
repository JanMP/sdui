import React from 'react'
import {MeteorTableDataHandler} from './MeteorTableDataHandler.coffee'
import {EditableDataTable} from './EditableDataTable.coffee'

export SdTable = ({dataOptions, customComponents}) ->
  <MeteorTableDataHandler
    dataOptions={dataOptions}
    DisplayComponent={EditableDataTable}
    customComponents={customComponents}
  />