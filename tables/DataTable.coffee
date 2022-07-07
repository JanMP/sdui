import React, {useEffect, useState, useRef} from "react"
import {AutoTableAutoField} from "./AutoTableAutoField.coffee"
import {
  Column, defaultTableRowRenderer, Table, CellMeasurer, CellMeasurerCache,
  InfiniteLoader
} from 'react-virtualized'
import Draggable from 'react-draggable'
import {useDebounce} from '@react-hook/debounce'
import {useThrottle} from '@react-hook/throttle'
import useSize from '@react-hook/size'
import _ from 'lodash'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faSortUp} from '@fortAwesome/free-solid-svg-icons/faSortUp'
import {faSortDown} from '@fortAwesome/free-solid-svg-icons/faSortDown'
import {faTrash} from '@fortAwesome/free-solid-svg-icons/faTrash'
import {faGripVertical} from '@fortAwesome/free-solid-svg-icons/faGripVertical'
import {DefaultHeader} from './DefaultHeader.coffee'


newCache = -> new CellMeasurerCache
  fixedWidth: true
  minHeight: 40
  defaultHeight: 200

resizableHeaderRenderer = ({onResizeRows, isLastOne}) ->
  ({columnData, dataKey, disableSort, label, sortBy, sortDirection}) ->

    onDrag = (e, {deltaX}) ->
      onResizeRows {dataKey, deltaX}
    
    <div className="w-full overflow-hidden flex justify-end items-center h-[34pt] #{if isLastOne then '' else 'border-r-2 border-secondary-300'}" key={dataKey}>
      <div className="flex-auto flex justify-between sort-click-target">
        <div className="flex-auto overflow-hidden whitespace-nowrap text-ellipsis sort-click-target">{label}</div>
        <div className="flex-none text-secondary-400 mr-2 sort-click-target">
          {
            if sortBy is dataKey
              if sortDirection is 'ASC'
                <FontAwesomeIcon className="sort-click-target" icon={faSortDown}/>
              else
                <FontAwesomeIcon className="sort-click-target" icon={faSortUp} />
          }
        </div>
      </div>
      {<Draggable
        axis="x"
        defaultClassName="flex-none cursor-col-resize text-secondary-500"
        defaultClassNameDragging="flex-none cursor-col-resize !text-secondary-200 "
        onDrag={onDrag}
        position={x: 0}
      >
        <FontAwesomeIcon
          className="mr-2"
          icon={faGripVertical}
        />
      </Draggable> unless isLastOne}
    </div>


cellRenderer = ({listSchemaBridge, onChangeField, cache, mayEdit}) ->
  ({dataKey, parent, rowIndex, columnIndex, cellData, rowData}) ->
    options = listSchemaBridge.schema._schema[dataKey].sdTable ? {}
    cache.clear {rowIndex, columnIndex}
    <CellMeasurer
      cache={cache}
      columnIndex={columnIndex}
      key={dataKey}
      parent={parent}
      rowIndex={rowIndex}
    >
      {({measure}) ->
        <AutoTableAutoField
          row={rowData}
          columnKey={dataKey}
          schemaBridge={listSchemaBridge}
          onChangeField={onChangeField}
          measure={measure}
          mayEdit={mayEdit}
        />}
    </CellMeasurer>

# TODO Think this through 
actionCellRenderer = ({component}) ->
({dataKey, parent, rowIndex, columnIndex, cellData, rowData}) ->
  onClick = (e) ->
    e.stopPropagation()
    e.nativeEvent.stopImmediatePropagation()
    if (id = rowData?._id ? rowData?.id)?
      onDelete {id}

  <div style={paddingTop: ".5rem"}>
    <button
      onClick={onClick}
      className="danger icon"
    >
      <FontAwesomeIcon icon={faTrash}/>
    </button>
  </div>

deleteButtonCellRenderer = ({mayDelete, onDelete}) ->
  ({dataKey, parent, rowIndex, columnIndex, cellData, rowData}) ->

    id = rowData?._id ? rowData?.id

    onClick = (e) ->
      e.stopPropagation()
      e.nativeEvent.stopImmediatePropagation()
      if id?
        onDelete {id}

    <div style={paddingTop: ".5rem"}>
      <button
        onClick={onClick}
        className="danger icon"
        disabled={rowData._disableDeleteForRow or not mayDelete}
      >
        <FontAwesomeIcon icon={faTrash}/>
      </button>
    </div>

rowRenderer = ({canEdit, mayEdit}) ->
  (props) ->
    if canEdit
      if mayEdit and not props.rowData._disableEditForRow
        props.className += " editable-row"
      else
        props.className += " not-editable-row"
        props.onRowClick = ->
    defaultTableRowRenderer props


export DataTable = ({
  sourceName,
  listSchemaBridge,
  rows, limit, totalRowCount,
  loadMoreRows = (args...) -> console.log "loadMoreRows default stump called with arguments:", args...
  canSort, sortColumn, sortDirection,
  onChangeSort = (args...) -> console.log "onChangeSort default stump called with arguments:", args...
  canSearch, search,
  onChangeSearch = (args...) -> console.log "onChangeSearch default stump called with arguments:", args...
  canQuery, onChangeQueryUiObject
  isLoading
  canAdd, mayAdd, onAdd = (args...) -> console.log "onAdd default stump called with arguments:", args...
  canDelete, mayDelete, onDelete = (args...) -> console.log "onDelete default stump called with arguments:", args...
  canEdit, mayEdit,
  onChangeField = (args...) -> console.log "onChangeField default stump called with arguments:", args...
  onRowClick
  canExport, onExportTable = (args...) -> console.log "onExportTable default stump called with arguments:", args...
  mayExport
  overscanRowCount = 10
  customComponents = {}
}) ->

  {Header, actionCell} = customComponents
  Header ?= DefaultHeader
  {renderer, width} = actionCell ? {}

  if actionCell? and not (renderer? and width?)
    throw new Error 'actionCell custom Component must have Fields renderer and width'

  schema = listSchemaBridge.schema

  deleteColumnWidth = 50

  cacheRef = useRef newCache()

  headerContainerRef = useRef null
  [headerContainerWidth, headerContainerHeight] = useSize headerContainerRef

  contentContainerRef = useRef null
  [contentContainerWidth, contentContainerHeight] = useSize contentContainerRef

  tableRef = useRef null
  oldRows = useRef null

  columnKeys =
    schema._firstLevelSchemaKeys
    .filter (key) ->
      options = schema._schema[key].sdTable ? {}
      if key in ['id', '_id']
        not (options.hide ? true) # don't include ids by default
      else
        not (options.hide ? false)

  defaultColumnWidths = columnKeys.map (key, i, arr) ->
    schema._schema[key].sdTable?.columnWidth ? 1 / (if arr.length then arr.length else 20)

  getColumnWidthsFromLocalStorage = ->
    if global.localStorage
      try
        savedColumnWidths = JSON.parse(global.localStorage.getItem sourceName)?.columnWidths
        if savedColumnWidths?.length is defaultColumnWidths.length then savedColumnWidths
      catch error
        console.error error

  saveColumnWidthsToLocalStorage = (newWidths) ->
    if global.localStorage
      currentEntry = (try JSON.parse global.localStorage.getItem sourceName) ? {}
      global.localStorage.setItem sourceName, JSON.stringify {currentEntry..., columnWidths: newWidths}

  [columnWidths, setColumnWidths] = useState getColumnWidthsFromLocalStorage() ? defaultColumnWidths
  totalColumnsWidth = contentContainerWidth - if canDelete then deleteColumnWidth else 0

  [debouncedResetTrigger, setDebouncedResetTrigger] = useThrottle 0, 30

  onResizeRows = ({dataKey, deltaX}) ->
    newWidths = [columnWidths...]
    if dataKey? and deltaX?
      ratioDeltaX = deltaX / totalColumnsWidth
      i = _.findIndex columnKeys, (key) -> key is dataKey
      newWidths[i] += ratioDeltaX
      newWidths[i + 1] -= ratioDeltaX
    if _.some newWidths, (w) -> w * totalColumnsWidth < 25
      newWidths = columnWidths.map (w) -> Math.max w, 25 / totalColumnsWidth
      sumOfNewWidths = _.sum newWidths
      newWidths = newWidths.map (w) -> w / sumOfNewWidths
    setColumnWidths newWidths
    saveColumnWidthsToLocalStorage newWidths
    setDebouncedResetTrigger debouncedResetTrigger + 1

  sort = ({event, defaultSortDirection, sortBy, sortDirection}) ->
    if 'sort-click-target' in event?.nativeEvent?.srcElement?.classList
      onChangeSort
        sortColumn: sortBy
        sortDirection: sortDirection

  useEffect ->
    if (newColumnWidths = getColumnWidthsFromLocalStorage())?
      setColumnWidths newColumnWidths
  , [sourceName]

  useEffect ->
    cacheRef.current.clearAll()
    tableRef?.current?.forceUpdateGrid?()
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

  columns =
    columnKeys.map (key, i, arr) ->
      schemaForKey = schema._schema[key]
      options = schemaForKey.sdTable ? {}
      isLastOne = i is arr.length - 1
      className = if options.overflow then 'overflow'
      headerRenderer = resizableHeaderRenderer({onResizeRows, isLastOne}) #unless isLastOne
      <Column
        className={className}
        key={key}
        dataKey={key}
        label={schemaForKey.label}
        width={columnWidths[i] * totalColumnsWidth}
        cellRenderer={cellRenderer {listSchemaBridge, onChangeField, mayEdit, cache: cacheRef.current}}
        headerRenderer={headerRenderer}
      />


  <div ref={contentContainerRef} style={height: '100%'} className="bg-white">
  
    <div ref={headerContainerRef}>
      <Header {{
        listSchemaBridge
        loadedRowCount: rows?.length, totalRowCount
        canSearch, search, onChangeSearch
        canQuery, onChangeQueryUiObject
        canExport, mayExport, onExportTable,
        canAdd, mayAdd, onAdd
        canSort, sortColumn, sortDirection, onChangeSort
      }...}/>
    </div>
   
      <InfiniteLoader
        isRowLoaded={isRowLoaded}
        loadMoreRows={loadMoreRows}
        rowCount={totalRowCount}
      >
        {({onRowsRendered, registerChild}) ->
          registerChild tableRef
          <Table
            width={contentContainerWidth}
            height={contentContainerHeight - headerContainerHeight - 10}
            headerHeight={34}
            rowHeight={cacheRef.current.rowHeight}
            rowCount={rows?.length ? 0}
            rowGetter={getRow}
            rowClassName={({index}) -> if index %% 2 then 'uneven' else 'even'}
            rowRenderer={rowRenderer {canEdit, mayEdit}}
            onRowsRendered={onRowsRendered}
            ref={tableRef}
            overscanRowCount={overscanRowCount}
            onRowClick={onRowClick}
            sort={sort}
            sortBy={sortColumn}
            sortDirection={sortDirection}
          >
            {columns}
            {
              if actionCell?.render?
                <Column
                  dataKey="no-data-key"
                  label=""
                  width={deleteColumnWidth}
                  cellRenderer={actionCell?.render}
                />
              else if canDelete
                <Column
                  dataKey="no-data-key"
                  label=""
                  width={deleteColumnWidth}
                  cellRenderer={deleteButtonCellRenderer {mayDelete, onDelete}}
                />
            }
          </Table>
        }
      </InfiniteLoader>
    
  </div>