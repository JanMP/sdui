import React, {useState, useEffect, useRef} from 'react'
import {DataList} from './DataList.coffee'
import {TableEditModalHandler} from './TableEditModalHandler.coffee'

export EditableDataList = (tableOptions) ->
  <TableEditModalHandler
    tableOptions={tableOptions}
    DisplayComponent={DataList}
  />