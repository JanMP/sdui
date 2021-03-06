import React from 'react'
import {MeteorTableDataHandler} from './MeteorTableDataHandler.coffee'
import {EditableDataList} from './EditableDataList.coffee'

export SdList = ({dataOptions, customComponents}) ->
  <MeteorTableDataHandler
    dataOptions={dataOptions}
    DisplayComponent={EditableDataList}
    customComponents={customComponents}
  />