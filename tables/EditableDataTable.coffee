import React, {useState, useEffect, useRef} from 'react'
# import {Button, Icon, Modal} from 'semantic-ui-react'
import {DataTable} from './DataTable.coffee'
import {TableEditModalHandler} from './TableEditModalHandler.coffee'

export EditableDataTable = (tableOptions) ->
  <TableEditModalHandler
    tableOptions={tableOptions}
    DisplayComponent={DataTable}
  />