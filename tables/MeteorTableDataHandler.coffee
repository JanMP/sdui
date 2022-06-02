import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import React, {useState, useEffect, useRef} from 'react'
import {meteorApply} from '../common/meteorApply.coffee'
import {DataList} from './DataList.coffee'
import {ErrorBoundary} from '../common/ErrorBoundary.coffee'
import {useTracker} from 'meteor/react-meteor-data'
import {toast} from 'react-toastify'
import {useCurrentUserIsInRole} from '../common/roleChecks.coffee'
import {getColumnsToExport} from '../common/getColumnsToExport.coffee'
import Papa from 'papaparse'
import {downloadAsFile} from '../common/downloadAsFile.coffee'
import _ from 'lodash'


defaultQuery = {} # ensures equality between runs

###*
  @typedef {import("../interfaces").DataTableOptions} DataTableOptions
  ###
###*
  @typedef {import("../interfaces").DataTableDisplayOptions} DataTableDisplayOptions
  ###

###*
  @type {
    (options: {
      dataOptions: DataTableOptions,
      DisplayComponent: {(options: TableDataDisplayOptions) => JSX.Element},
      customComponents?: any
    }) => JSX.Element
  }
  ###
export MeteorTableDataHandler = ({dataOptions, DisplayComponent, customComponents}) ->
  {
  sourceName, listSchemaBridge,
  rowsCollection, rowCountCollection
  query = defaultQuery
  initialSortColumn
  initialSortDirection
  perLoad = 500
  canEdit = false
  formSchemaBridge
  canSearch = false
  canAdd = false
  canDelete = false
  onDelete
  canExport = false
  onRowClick
  autoFormChildren
  formDisabled = false
  formReadOnly = false
  viewTableRole, editRole, exportTableRole, #TODO add handling of viewTableRole
  } = dataOptions

  # we only support usePubSub = true atm
  usePubSub = true

  if usePubSub and not (rowsCollection? and rowCountCollection?)
    throw new Error 'usePubSub is true but rowsCollection or rowCountCollection not given'

  if sourceName?
    getRowMethodName = "#{sourceName}.getRows"
    getRowCountMethodName = "#{sourceName}.getCount"
    rowPublicationName = "#{sourceName}.rows"
    rowCountPublicationName = "#{sourceName}.count"
    submitMethodName = "#{sourceName}.submit"
    setValueMethodName = "#{sourceName}.setValue"
    fetchEditorDataMethodName = "#{sourceName}.fetchEditorData"
    deleteMethodName = "#{sourceName}.delete"
    exportRowsMethodName = "#{sourceName}.getExportRows"

  formSchemaBridge ?= listSchemaBridge

  if onRowClick and canEdit
    throw new Error 'both onRowClick and canEdit set to true'

  resolveRef = useRef ->
  rejectRef = useRef ->

  [rows, setRows] = useState []
  [totalRowCount, setTotalRowCount] = useState 0
  [limit, setLimit] = useState perLoad

  [isLoading, setIsLoading] = useState false

  [sortColumn, setSortColumn] = useState initialSortColumn
  [sortDirection, setSortDirection] = useState initialSortDirection
  
  [search, setSearch] = useState ''
  # [debouncedSearch, setDebouncedSearch] = useDebounce '', 1000

  mayEdit = useCurrentUserIsInRole editRole
  mayExport = (useCurrentUserIsInRole exportTableRole) and rows?.length

  if sortColumn? and sortDirection?
    sort = "#{sortColumn}": if sortDirection is 'ASC' then 1 else -1


  getRows = ->
    return if usePubSub
    setIsLoading true
    meteorApply
      method: getRowMethodName
      data: {search, query, sort, limit, skip}
    .then (returnedRows) ->
      setRows returnedRows
      setIsLoading false
    .catch (error) ->
      console.error error
      setIsLoading false

  getTotalRowCount = ->
    return if usePubSub
    meteorApply
      method: getRowCountMethodName
      data: {search, query}
    .then (result) ->
      setTotalRowCount result?[0]?.count or 0
    .catch console.error

  useEffect ->
    if query?
      getTotalRowCount()
    return
  , [search, query, sourceName]

  useEffect ->
    setLimit perLoad
    return
  , [search, query, sortColumn, sortDirection, sourceName]

  skip = 0

  subLoading = useTracker ->
    return unless usePubSub
    handle = Meteor.subscribe rowPublicationName, {search, query, sort, skip, limit}
    not handle.ready()
  
  useEffect ->
    setIsLoading subLoading
  , [subLoading]
  
  countSubLoading = useTracker ->
    return unless usePubSub
    handle = Meteor.subscribe rowCountPublicationName, {query, search}
    not handle.ready()

  subRowCount = useTracker ->
    return unless usePubSub
    rowCountCollection.findOne({})?.count or 0
  
  useEffect ->
    setTotalRowCount subRowCount
  , [subRowCount]

  subRows = useTracker ->
    return unless usePubSub
    rowsCollection.find(query, {sort, limit}).fetch()

  useEffect ->
    unless _.isEqual subRows, rows
      setRows subRows
    return
  , [subRows]

  useEffect ->
    resolveRef.current() unless isLoading
  , [subLoading]

  loadMoreRows = ({startIndex, stopIndex}) ->
    if stopIndex >= limit
      setLimit limit + perLoad
    new Promise (res, rej) ->
      resolveRef.current = res
      rejectRef.current = rej

  onChangeSort = (d) ->
    setSortColumn d.sortColumn
    setSortDirection d.sortDirection

  submit = (d) ->
    meteorApply
      method: submitMethodName
      data: d
    .then (results) ->
      getRows()
      results
    .catch (error) ->
      toast.error "#{error}"
      console.log error

  loadEditorData = ({id}) ->
    unless id?
      throw new Error 'loadEditorData: no id'
    meteorApply
      method: fetchEditorDataMethodName
      data: {id}
    .catch console.error

  onChangeSearch = (d) ->
    setSearch d

  onDelete ?= ({id}) ->    # setConfirmationModalOpen false
    meteorApply
      method: deleteMethodName
      data: {id}
    .then ->
      toast.success "Der Eintrag wurde gelöscht"
  
  onChangeField = ({_id, changeData}) ->
    meteorApply
      method: setValueMethodName
      data: {_id, changeData}
    .catch console.error
   
  onExportTable = ->
    if canExport
      meteorApply
        method: exportRowsMethodName
        data: {search, query, sort}
      .then (rows) ->
        toast.success "Exportdaten vom Server erhalten"
        Papa.unparse rows, columns: getColumnsToExport schema: listSchemaBridge.schema
      .then (csvString) ->
        downloadAsFile
          dataString: csvString
          fileName: (title ? sourceName) + '.csv'
      .catch (error) ->
        console.error error
        toast.error "Fehler (siehe console.log)"
    else throw new Meteor.Error 'onExportTable has been called despite canExport == false'

  <ErrorBoundary>
    <DisplayComponent {{
      sourceName,
      listSchemaBridge, formSchemaBridge
      rows, totalRowCount, loadMoreRows, onRowClick,
      sortColumn, sortDirection, onChangeSort
      canSearch, search, onChangeSearch
      canAdd
      canDelete, onDelete
      canEdit, mayEdit, submit
      autoFormChildren, formDisabled, formReadOnly
      loadEditorData
      onChangeField,
      canExport, onExportTable
      mayExport
      isLoading,
      customComponents
    }...} />
  </ErrorBoundary>