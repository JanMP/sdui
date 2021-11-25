import React from 'react'
import {MeteorTableDataHandler} from './MeteorTableDataHandler.coffee'
import {DataList} from './DataList.coffee'

export SdList = ({dataOptions, customComponents}) ->
  <MeteorTableDataHandler
    dataOptions={dataOptions}
    DisplayComponent={DataList}
  />