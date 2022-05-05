import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {publishTableData} from './publishTableData.coffee'
import {createTableDataMethods} from './createTableDataMethods.coffee'
import {createDefaultPipeline} from './createDefaultPipeline.coffee'
import SimpleSchema2Bridge from 'uniforms-bridge-simple-schema-2'

###*
  @typedef {import("../interfaces").createTableDataAPIReturn} createTableDataAPIReturn
  ###
###*
  @typedef {import("../interfaces").createTableDataAPIParams} createTableDataAPIParams
  ###
###*
  @type {(options: createTableDataAPIParams) => createTableDataAPIReturn}
  ###
export createTableDataAPI = ({
  sourceName, sourceSchema, collection
  useObjectIds
  listSchema, formSchema
  canEdit, canSearch, canAdd, canDelete, canExport
  viewTableRole, editRole, exportTableRole
  getPreSelectPipeline
  getProcessorPipeline,
  # CHECK if they work or if we should get rid of the following:
  getRowsPipeline, getRowCountPipeline, getExportPipeline
  makeFormDataFetchMethodRunFkt, makeSubmitMethodRunFkt, makeDeleteMethodRunFkt
  debounceDelay
  observers
  setupNewItem
  checkDisableEditForRow
  checkDisableDeleteForRow
}) ->

  # check required props and setup defaults for optional props
  unless sourceName?
    throw new Error 'no sourceName given'

  unless sourceSchema?
    throw new Error 'no sourceSchema given'

  unless viewTableRole?
    viewTableRole = 'any'
    console.warn "[createTableDataAPI #{sourceName}]:
      no viewTableRole defined, using '#{viewTableRole}' instead."

  if canEdit and not editRole?
    editRole = viewTableRole
    console.warn "[createTableDataAPI #{sourceName}]:
      no editRole defined, using '#{editRole}' instead."

  if canExport and not exportTableRole?
    exportTableRole = viewTableRole
    console.warn "[createTableDataAPI #{sourceName}]:
      no exportTableRole defined, using '#{exportTableRole}' instead."
  
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
    viewTableRole, editRole, exportTableRole, sourceName, collection, useObjectIds,
    getRowsPipeline, getRowCountPipeline, getExportPipeline
    canEdit, canDelete, canExport, formSchema,
    makeFormDataFetchMethodRunFkt, makeSubmitMethodRunFkt, makeDeleteMethodRunFkt
    checkDisableDeleteForRow, checkDisableEditForRow
  }


  #return props for the ui component
  {
    sourceName, listSchemaBridge, formSchemaBridge
    rowsCollection, rowCountCollection
    canEdit
    canSearch
    canAdd
    canDelete
    canExport
    viewTableRole
    editRole
    exportTableRole
    setupNewItem
  }