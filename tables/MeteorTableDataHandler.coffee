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
  @typedef {Object} SDTableDataOptionsType
  @property {string} sourceName
  @property {any} listSchemaBridge
  @property {Mongo.Collection} rowsCollection
  @property {Mongo.Collection} rowCountCollection
  @property {Object?} query - defaults to defaultQuery
  @property {number?} perLoad - defaults to 500
  @property {boolean?} canEdit - defaults to false
  @property {any} formSchemaBridge
  @property {boolean?} canSearch - defaults to false
  @property {boolean?} canAdd - defaults to false
  @property {() => void} onAdd
  @property {boolean?} canDelete - defaults to false
  @property {string?} deleteConfirmation - defaults to "Soll der Eintrag wirklich gelöscht werden?"
  @property {(id: string) => void} onDelete
  @property {boolean?} canExport - defaults to false
  @property {() => void} onExportTable
  @property {(id: string) => void} onRowClick
  @property {[any]?} autoFormChildren
  @property {boolean?} formDisabled - defaults to false
  @property {boolean?} formReadOnly - defaults to false
  @property {boolean?} useSort - defaults to true
  @property {string?} getRowCountMethodName - defaults to method name set up by createTableDataAPI
  @property {string?} getRowMethodName - defaults to method name set up by createTableDataAPI
  @property {string?} rowPublicationName - defaults to method name set up by createTableDataAPI
  @property {string?} rowCountPublicationName - defaults to method name set up by createTableDataAPI
  @property {string?} submitMethodName - defaults to method name set up by createTableDataAPI
  @property {string?} deleteMethodName - defaults to method name set up by createTableDataAPI
  @property {string?} fetchEditorDataMethodName - defaults to method name set up by createTableDataAPI
  @property {string?} setValueMethodName - defaults to method name set up by createTableDataAPI
  @property {string?} exportRowsMethodName - defaults to method name set up by createTableDataAPI
  @property {string} viewTableRole
  @property {string} editRole
  @property {string} exportTableRole
  ###

###*
  @typedef {Object} SDTableDisplayComponentArgumentsType
  @property {string} sourceName
  @property {any} listSchemaBridge
  @property {any} formSchemaBridge
  @property {Array} rows
  @property {number} totalRowCount
  @property {any} loadMoreRows
  @property {(id: string) => void} onRowClick
  @property {any} sortColumn
  @property {any} sortDirection
  @property {() => void} onChangeSort
  @property {boolean?} useSort
  @property {boolean?} canSearch
  @property {string} search
  @property {() => void} onChangeSearch
  @property {boolean?} canAdd
  @property {() => void} onAdd
  @property {boolean?} canDelete
  @property {boolean?} onDelete
  @property {string} deleteConfirmation
  @property {boolean?} canEdit
  @property {boolean?} mayEdit
  @property {() => void} submit
  @property {[any]} autoFormChildren
  @property {boolean?} formDisabled
  @property {boolean?} formReadOnly
  @property {(id: string) => void} loadEditorData
  @property {() => void} onChangeField
  @property {boolean?} canExport
  @property {() => void} onExportTable
  @property {boolean?} mayExport
  @property {boolean} isLoading
  @property {Object} customComponents
  ###  

###*
  @param {Object} args
  @param {SDTableDataOptionsType} args.dataOptions
  @param {(SDTableDisplayComponentArgumentsType) => JSX.Element} args.DisplayComponent
  @param {Object} args.customComponents
  ###
export MeteorTableDataHandler = ({dataOptions, DisplayComponent, customComponents}) ->
  {
  sourceName, listSchemaBridge,
  rowsCollection, rowCountCollection
  query = defaultQuery
  perLoad = 500
  canEdit = false
  formSchemaBridge
  canSearch = false
  canAdd = false
  onAdd
  canDelete = false
  deleteConfirmation = "Soll der Eintrag wirklich gelöscht werden?"
  onDelete
  canExport = false
  onExportTable
  onRowClick
  autoFormChildren
  formDisabled = false
  formReadOnly = false
  useSort = true
  getRowMethodName, getRowCountMethodName
  rowPublicationName, rowCountPublicationName
  submitMethodName, deleteMethodName, fetchEditorDataMethodName
  setValueMethodName
  exportRowsMethodName,
  viewTableRole, editRole, exportTableRole, #TODO add handling of viewTableRole
  } = dataOptions

  # we only support usePubSub = true atm
  usePubSub = true

  if usePubSub and not (rowsCollection? and rowCountCollection?)
    throw new Error 'usePubSub is true but rowsCollection or rowCountCollection not given'

  if sourceName?
    getRowMethodName ?= "#{sourceName}.getRows"
    getRowCountMethodName ?= "#{sourceName}.getCount"
    rowPublicationName ?= "#{sourceName}.rows"
    rowCountPublicationName ?= "#{sourceName}.count"
    submitMethodName ?= "#{sourceName}.submit"
    setValueMethodName ?= "#{sourceName}.setValue"
    fetchEditorDataMethodName ?= "#{sourceName}.fetchEditorData"
    deleteMethodName ?= "#{sourceName}.delete"
    exportRowsMethodName ?= "#{sourceName}.getExportRows"

  formSchemaBridge ?= listSchemaBridge

  if onRowClick and canEdit
    throw new Error 'both onRowClick and canEdit set to true'

  onRowClick ?= ->

  resolveRef = useRef ->
  rejectRef = useRef ->

  [rows, setRows] = useState []
  [totalRowCount, setTotalRowCount] = useState 0
  [limit, setLimit] = useState perLoad

  [isLoading, setIsLoading] = useState false

  [sortColumn, setSortColumn] = useState undefined
  [sortDirection, setSortDirection] = useState undefined
  
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
   
  if canExport
    onExportTable ?= ->
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


  <ErrorBoundary>
    <DisplayComponent {{
      sourceName,
      listSchemaBridge, formSchemaBridge
      rows, totalRowCount, loadMoreRows, onRowClick,
      sortColumn, sortDirection, onChangeSort, useSort
      canSearch, search, onChangeSearch
      canAdd, onAdd
      canDelete, onDelete, deleteConfirmation
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