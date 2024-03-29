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
import {DefaultHeader} from './DefaultHeader.coffee'
import {useTranslation} from 'react-i18next'
import {Button} from 'primereact/button'

newCache = -> new CellMeasurerCache
  fixedWidth: true
  minHeight: 40
  defaultHeight: 200

resizableHeaderRenderer = ({onResizeRows, isLastOne}) ->
  ({columnData, dataKey, disableSort, label, sortBy, sortDirection}) ->
  
    onDrag = (e, {deltaX}) ->
      onResizeRows {dataKey, deltaX}
    
    <div className={"content #{if isLastOne then 'last-column' else ''}"} key={dataKey}>
      <div className="squishy sort-click-target">
        <div className="label sort-click-target">{label}</div>
        <div className="sort-icon sort-click-target">
          {
            if sortBy is dataKey
              if sortDirection is 'ASC'
                <i className="sort-click-target pi pi-sort-down"/>
              else
                <i className="sort-click-target pi pi-sort-up" />
            else
              <i className="sort-click-target pi pi-sort"/>
          }
        </div>
      </div>
      {<Draggable
        axis="x"
        defaultClassName="drag-handle"
        defaultClassNameDragging="drag-handle"
        onDrag={onDrag}
        position={x: 0}
      >
        <i className="pi pi-arrows-h"/>
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


rightButtonCellRenderer = ({canDelete, mayDelete, onDelete, AdditionalButtonsRight}) ->
  ({dataKey, parent, rowIndex, columnIndex, cellData, rowData}) ->

    id = rowData?._id ? rowData?.id
    AdditionalButtonsRight ?= -> null

    onClick = (e) ->
      e.stopPropagation()
      e.nativeEvent.stopImmediatePropagation()
      if id?
        onDelete {id}

    <div className="pt-2">
      <AdditionalButtonsRight rowData={rowData}/>
     {<Button
        onClick={onClick}
        rounded text
        severity="danger"
        icon="pi pi-delete-left"
        disabled={rowData._disableDeleteForRow or not mayDelete}
      /> if canDelete}
    </div>

rowRenderer = ({canEdit, mayEdit}) ->
  (props) ->
    if canEdit
      if mayEdit and not props.rowData._disableEditForRow
        props.className += " cursor-pointer"
      else
        props.className += " cursor-not-allowed"
        props.onRowClick = ->
    defaultTableRowRenderer props


export DataTable = ({
  sourceName,
  listSchemaBridge,
  queryEditorSchemaBridge
  rows, limit, totalRowCount,
  loadMoreRows = (args...) -> console.log "loadMoreRows default stump called with arguments:", args...
  canSort, sortColumn, sortDirection,
  onChangeSort = (args...) -> console.log "onChangeSort default stump called with arguments:", args...
  canSearch, search,
  onChangeSearch = (args...) -> console.log "onChangeSearch default stump called with arguments:", args...
  canUseQueryEditor, queryUiObject, onChangeQueryUiObject
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

  {t} = useTranslation()

  {Header, AdditionalButtonsRight, rightButtonColumnWidth, AdditionalHeaderButtonsLeft, AdditionalHeaderButtonsRight} = customComponents
  if Header? and (AdditionalHeaderButtonsLeft? or AdditionalHeaderButtonsRight?)
    console.warn "both Header and AdditionalHeaderButtons are declared"
  
  Header ?= DefaultHeader

  rightButtonColumnWidth ?= 50

  schema = listSchemaBridge.schema

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
  totalColumnsWidth = contentContainerWidth - if canDelete then rightButtonColumnWidth else 0

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
        label={t key, schemaForKey.label}
        width={columnWidths[i] * totalColumnsWidth}
        cellRenderer={cellRenderer {listSchemaBridge, onChangeField, mayEdit, cache: cacheRef.current}}
        headerRenderer={headerRenderer}
      />


  <div ref={contentContainerRef} className="p-component h-full">
  
    <div ref={headerContainerRef}>
      <Header {{
        listSchemaBridge
        queryEditorSchemaBridge
        loadedRowCount: rows?.length, totalRowCount
        canSearch, search, onChangeSearch
        canUseQueryEditor, queryUiObject, onChangeQueryUiObject
        canExport, mayExport, onExportTable,
        canAdd, mayAdd, onAdd
        canSort, sortColumn, sortDirection, onChangeSort
        AdditionalHeaderButtonsLeft, AdditionalHeaderButtonsRight
      }...}/>
    </div>
   
    <div className="absolute">
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
              if canDelete or AdditionalButtonsRight?
                <Column
                  dataKey="no-data-key"
                  label=""
                  width={rightButtonColumnWidth}
                  cellRenderer={rightButtonCellRenderer {canDelete, mayDelete, onDelete, AdditionalButtonsRight}}
                />
            }
          </Table>
        }
      </InfiniteLoader>
    </div>
    
  </div>