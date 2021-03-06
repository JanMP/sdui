import React, {useEffect, useState, useRef} from "react"
import {AutoTableAutoField} from "./AutoTableAutoField.coffee"
import {SearchInput} from "./SearchInput.coffee"
import {List, CellMeasurer, CellMeasurerCache,InfiniteLoader} from 'react-virtualized'
import Draggable from 'react-draggable'
import {useDebounce} from '@react-hook/debounce'
import {useThrottle} from '@react-hook/throttle'
import useSize from '@react-hook/size'
import _ from 'lodash'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faPlus} from '@fortawesome/free-solid-svg-icons/faPlus'
import {faFileDownload} from '@fortawesome/free-solid-svg-icons/faFileDownload'
import {faSortUp} from '@fortawesome/free-solid-svg-icons/faSortUp'
import {faSortDown} from '@fortawesome/free-solid-svg-icons/faSortDown'
import {faTrash} from '@fortawesome/free-solid-svg-icons/faTrash'
import {DefaultListItem} from './DefaultListItem.coffee'
import {DefaultHeader} from './DefaultHeader.coffee'


newCache = -> new CellMeasurerCache
  fixedWidth: true
  minHeight: 30
  defaultHeight: 200


export DataList = ({
  sourceName,
  listSchemaBridge,
  rows, limit, totalRowCount,
  loadMoreRows = (args...) -> console.log "loadMoreRows default stump called with arguments:", args...
  useSort, sortColumn, sortDirection,
  onChangeSort = (args...) -> console.log "onChangeSort default stump called with arguments:", args...
  canSearch, search,
  onChangeSearch = (args...) -> console.log "onChangeSearch default stump called with arguments:", args...
  isLoading
  canAdd, onAdd = (args...) -> console.log "onAdd default stump called with arguments:", args...
  canDelete, onDelete = (args...) -> console.log "onDelete default stump called with arguments:", args...
  canEdit, mayEdit,
  onChangeField = (args...) -> console.log "onChangeField default stump called with arguments:", args...
  onRowClick
  canExport, onExportTable = (args...) -> console.log "onExportTable default stump called with arguments:", args...
  mayExport
  overscanRowCount = 10
  customComponents = {}
  selectedRowId = null
}) ->

  {Header, ListItem, ListItemContent} = customComponents

  ListItem ?= DefaultListItem
  Header ?= DefaultHeader

  schema = listSchemaBridge.schema

  cacheRef = useRef newCache()

  headerContainerRef = useRef null
  [headerContainerWidth, headerContainerHeight] = useSize headerContainerRef

  contentContainerRef = useRef null
  [contentContainerWidth, contentContainerHeight] = useSize contentContainerRef

  tableRef = useRef null
  oldRows = useRef null

  [debouncedResetTrigger, setDebouncedResetTrigger] = useThrottle 0, 30

  onResizeRows = ({dataKey, deltaX}) ->
    prevWidths = columnWidths
    ratioDeltaX = deltaX / totalColumnsWidth
    i = _.findIndex columnKeys, (key) -> key is dataKey
    prevWidths[i] += ratioDeltaX
    prevWidths[i + 1] -= ratioDeltaX
    setColumnWidths prevWidths
    saveColumnWidthsToLocalStorage prevWidths
    setDebouncedResetTrigger debouncedResetTrigger + 1


  useEffect ->
    cacheRef.current.clearAll()
  , [contentContainerWidth, contentContainerHeight, debouncedResetTrigger]

  useEffect ->
    length = rows?.length ? 0
    oldLength = oldRows?.current?.length ? 0
    if length > oldLength
      cacheRef.current.clearAll() unless _.isEqual rows?[0...oldLength], oldRows?.current
    else
      cacheRef.current.clearAll() unless _.isEqual rows, oldRows?.current
    tableRef?.current?.forceUpdateGrid()
    oldRows.current = rows
    return
  , [rows]

  getRow = ({index}) -> rows[index] ? {}
  isRowLoaded = ({index}) -> rows?[index]?

  rowRenderer = ({
    index, isScrolling, isVisible, key, parent, style
  }) ->
    <div key={key} style={style}>
      <CellMeasurer
        cache={cacheRef.current}
        columnIndex={0}
        key={key}
        parent={parent}
        rowIndex={index}
      >
        <ListItem
          rowData={getRow {index}}
          index={index}
          onDelete={onDelete}
          onClick={onRowClick}
          canDelete={canDelete}
          ListItemContent={ListItemContent}
          selectedRowId={selectedRowId}
        />
      </CellMeasurer>
    </div>


  <div ref={contentContainerRef} style={height: '100%'} className="bg-white">
  
    <div ref={headerContainerRef}>
      <Header
        loadedRowCount={rows?.length}
        totalRowCount={totalRowCount}
        canSearch={canSearch}
        search={search}
        onChangeSearch={onChangeSearch}
        canExport={canExport}
        onExportTable={onExportTable}
        mayExport={mayExport}
        canAdd={canAdd}
        onAdd={onAdd}
        mayEdit={mayEdit}
      />
    </div>
   
      <InfiniteLoader
        isRowLoaded={isRowLoaded}
        loadMoreRows={loadMoreRows}
        rowCount={totalRowCount}
      >
        {({onRowsRendered, registerChild}) ->
          registerChild tableRef
          <List
            width={contentContainerWidth}
            height={contentContainerHeight - headerContainerHeight - 10}
            rowHeight={cacheRef.current.rowHeight}
            rowCount={rows?.length ? 0}
            overscanRowCount={overscanRowCount}
            onRowsRendered={onRowsRendered}
            rowRenderer={rowRenderer}
          />
        }
      </InfiniteLoader>
    
  </div>