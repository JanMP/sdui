import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {publishTableData} from './publishTableData.coffee'
import {createTableDataMethods} from './createTableDataMethods.coffee'
import {createDefaultPipeline} from './createDefaultPipeline.coffee'
import SimpleSchema2Bridge from 'uniforms-bridge-simple-schema-2'
import * as types from '../typeDeclarations'

###*
  @type {types.createTableDataAPI}
  ###
export createTableDataAPI = ({
  sourceName, sourceSchema, collection
  useObjectIds
  listSchema, formSchema
  canEdit, canSearch, canUseQueryEditor, canSort, canAdd, canDelete, canExport
  viewTableRole, editRole, addRole, deleteRole, exportTableRole
  getPreSelectPipeline
  getProcessorPipeline,
  # CHECK if they work or if we should get rid of the following:
  getRowsPipeline, getRowCountPipeline, getExportPipeline
  makeFormDataFetchMethodRunFkt, makeSubmitMethodRunFkt, makeDeleteMethodRunFkt
  debounceDelay
  observers
  query, initialSortColumn, initialSortDirection
  perLoad,
  setupNewItem
  showRowCount
  checkDisableEditForRow
  checkDisableDeleteForRow
}) ->

  # check required props and setup defaults for optional props
  unless sourceName?
    throw new Error 'no sourceName given'

  unless sourceSchema?
    throw new Error 'no sourceSchema given'

  canSearch ?= true
  canSort ?= true
  canUseQueryEditor ?= true

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
  formSchema ?= sourceSchema

  listSchemaBridge = new SimpleSchema2Bridge(listSchema)
  formSchemaBridge =
    if listSchema is formSchema
      listSchemaBridge
    else
      new SimpleSchema2Bridge(formSchema)

  {defaultGetRowsPipeline
  defaultGetRowCountPipeline
  defaultGetExportPipeline} = createDefaultPipeline {getPreSelectPipeline, getProcessorPipeline, listSchema}


  getRowsPipeline ?= defaultGetRowsPipeline
  getRowCountPipeline ?= defaultGetRowCountPipeline
  getExportPipeline ?= defaultGetExportPipeline

  setupNewItem ?= -> {}
  checkDisableEditForRow ?= false
  checkDisableDeleteForRow ?= false

  if Meteor.isClient # setup local collections for publications
    rowsCollection = new Mongo.Collection "#{sourceName}.rows"
    rowCountCollection = new Mongo.Collection "#{sourceName}.count"
  
  publishTableData {
    viewTableRole, sourceName, collection,
    getRowsPipeline, getRowCountPipeline, debounceDelay, observers
    }

  createTableDataMethods {
    viewTableRole, editRole, addRole, deleteRole, exportTableRole, sourceName, collection, useObjectIds,
    getRowsPipeline, getRowCountPipeline, getExportPipeline
    canEdit, canAdd, canDelete, canExport, formSchema,
    makeFormDataFetchMethodRunFkt, makeSubmitMethodRunFkt, makeDeleteMethodRunFkt
    checkDisableDeleteForRow, checkDisableEditForRow
  }


  #return props for the ui component
  {
    sourceName, listSchemaBridge, formSchemaBridge
    rowsCollection, rowCountCollection
    canEdit
    canSearch
    canSort
    canUseQueryEditor
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
    showRowCount
  }