import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {publishTableData} from './publishTableData.coffee'
import {createTableDataMethods} from './createTableDataMethods.coffee'
import {createDefaultPipeline} from './createDefaultPipeline.coffee'
import {Schema} from '../schema/Schema.coffee'
import * as types from '../typeDeclarations'

###*
  @type {types.createTableDataAPI}
  ###
export createTableDataAPI = ({
  sourceName, sourceSchema, collection
  useObjectIds
  listSchema, formSchema
  canEdit, canSearch, canSort, canAdd, canDelete, canExport
  viewTableRole, editRole, addRole, deleteRole, exportTableRole
  getPreSelectPipeline, getProcessorPipeline,
  getRowsPipeline, getExportPipeline
  makeFormDataFetchMethodRunFkt, makeSubmitMethodRunFkt, makeDeleteMethodRunFkt
  noAutomaticObserver
  debounceDelay
  getObservers
  query, initialSortColumn, initialSortDirection
  perLoad,
  setupNewItem
  onSubmit
  onDelete # CHECK if we use this, and remove or add to type declaration
  checkDisableEditForRow
  checkDisableDeleteForRow
  usePubSub
  embeddingModelSettings
  getEmbeddingText
}) ->

  # check required props and setup defaults for optional props
  unless sourceName?
    throw new Error 'no sourceName given'

  unless sourceSchema?
    throw new Error 'no sourceSchema given'

  if embeddingModelSettings? and not getEmbeddingText?
    throw new Error 'no getEmbeddingText given'

  if getEmbeddingText? and not embeddingModelSettings?
    throw new Error 'no embeddingModelSettings given'
  
  usePubSub ?= false
  canSearch ?= true
  canSort ?= true

  perLoad ?= 500

  if not viewTableRole? and Meteor.isServer
    console.warn "[createTableDataAPI #{sourceName}]:
      no viewTableRole defined, using 'any' instead."
  viewTableRole ?= 'any'

  if canEdit and not editRole? and Meteor.isServer
    console.warn "[createTableDataAPI #{sourceName}]:
      no editRole defined, using '#{viewTableRole}' instead."
  editRole ?= viewTableRole

  if canAdd and not addRole? and Meteor.isServer
    console.warn "[createTableDataAPI #{sourceName}]:
      no addRole defined, using '#{editRole}' instead."
  addRole ?= editRole

  if canDelete and not deleteRole? and Meteor.isServer
    console.warn "[createTableDataAPI #{sourceName}]:
      no deleteRole defined, using '#{editRole}' instead."
  deleteRole ?= editRole

  if canExport and not exportTableRole? and Meteor.isServer
    console.warn "[createTableDataAPI #{sourceName}]:
      no exportTableRole defined, using '#{viewTableRole}' instead."
  exportTableRole ?= viewTableRole
  
  getPreSelectPipeline ?= -> []
  getProcessorPipeline ?= -> []

  listSchema ?= sourceSchema
  formSchema ?= listSchema


  {defaultGetRowsPipeline, defaultGetExportPipeline} =
    createDefaultPipeline {getPreSelectPipeline, getProcessorPipeline, listSchema}


  getRowsPipeline ?= defaultGetRowsPipeline
  getExportPipeline ?= defaultGetExportPipeline

  setupNewItem ?= -> {}
  checkDisableEditForRow ?= false
  checkDisableDeleteForRow ?= false

  getObservers ?= -> []

  if Meteor.isClient # setup local collections for publications
    rowsCollection = new Mongo.Collection "#{sourceName}.rows"
  
  publishTableData {
    viewTableRole, sourceName, collection,
    getRowsPipeline,
    noAutomaticObserver, debounceDelay, getObservers
  }

  createTableDataMethods {
    viewTableRole, editRole, addRole, deleteRole, exportTableRole, sourceName, collection, useObjectIds,
    getRowsPipeline, getExportPipeline
    canEdit, canAdd, canDelete, canExport, formSchema,
    makeFormDataFetchMethodRunFkt, makeSubmitMethodRunFkt, makeDeleteMethodRunFkt
    checkDisableDeleteForRow, checkDisableEditForRow
  }


  #return props for the ui component
  {
    sourceName, listSchema, formSchema,
    rowsCollection
    canEdit
    canSearch
    canSort
    canAdd
    canDelete
    canExport
    viewTableRole
    editRole
    addRole
    deleteRole
    exportTableRole
    query, initialSortColumn, initialSortDirection
    perLoad
    setupNewItem
    onSubmit
    onDelete
    usePubSub
  }