import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import publishTableData from './publishTableData'
import createTableDataMethods from './createTableDataMethods.coffee'
import createDefaultPipeline from './createDefaultPipeline.coffee'
import SimpleSchema2Bridge from 'uniforms-bridge-simple-schema-2'


###*
  @param {{
    sourceName: string,
    sourceSchema: SimpleSchema,
    collection: Mongo.Collection,
    useObjectIds: boolean,
    listSchema: SimpleSchema,
    viewTableRole?: string,
    canSearch?: boolean,
    canEdit?: boolean,
    formSchema: SimpleSchema,
    editRole?: string,
    canAdd?: boolean,
    canDelete?: boolean,
    canExport?: boolean,
    exportTableRole?: string,
    getPreSelectPipeline?: () => Array,
    getProcessorPipeline?: () => Array,
    getRowsPipeline?: () => Array,
    getRowCountPipeline: () => Array,
    getExportPipeline: () => Array,
    rowsCollection?: Mongo.Collection,
    rowCountCollection?: Mongo.Collection,
    makeFormDataFetchMethodRunFkt?,
    makeSubmitMethodRunFkt?,
    makeDeleteMethodRunFkt?,
    debounceDelay?: number
  }}
  @return {{
    sourceName: string, listSchemaBridge, formSchemaBridge,
    rowsCollection: Mongo.Collection, rowCountCollection: Mongo.Collection,
    canEdit: boolean,
    canSearch: boolean,
    canAdd: boolean,
    canDelete: boolean,
    canExport: boolean,
    viewTableRole: string,
    editRole: string,
    exportTableRole: string,
  }} export this and import it as props into your react-component
  ###
createTableDataAPI = ({
  sourceName, sourceSchema, collection
  useObjectIds
  listSchema
  viewTableRole
  canSearch
  canEdit, formSchema,
  editRole
  canAdd
  canDelete
  canExport
  exportTableRole
  getPreSelectPipeline
  getProcessorPipeline,
  # CHECK if they work or if we should get rid of the following:
  getRowsPipeline, getRowCountPipeline, getExportPipeline
  rowsCollection, rowCountCollection
  makeFormDataFetchMethodRunFkt, makeSubmitMethodRunFkt, makeDeleteMethodRunFkt
  debounceDelay
}) ->

  # check required props and setup defaults for optional props
  unless sourceName?
    throw new Error 'no sourceName given'

  unless sourceSchema?
    throw new Error 'no sourceSchema given'

  unless viewTableRole?
    viewTableRole = 'any'
    console.warn "[createAutoDataTableBackend #{sourceName}]: no viewTableRole defined for AutoDataTableBackend #{sourceName}, using '#{viewTableRole}' instead."

  if canEdit and not editRole?
    editRole = viewTableRole
    console.warn "[createAutoDataTableBackend #{sourceName}]: no editRole defined for AutoDataTableBackend #{sourceName}, using '#{editRole}' instead."

  if canExport and not exportTableRole?
    exportTableRole = viewTableRole
    console.warn "[createAutoDataTableBackend #{sourceName}]: no exportTableRole defined for AutoDataTableBackend #{sourceName}, using '#{exportTableRole}' instead."
  
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

  if Meteor.isClient # setup local collections for publications
    rowsCollection ?= new Mongo.Collection "#{sourceName}.rows"
    rowCountCollection ?= new Mongo.Collection "#{sourceName}.count"
  
  publishTableData {
    viewTableRole, sourceName, collection,
    getRowsPipeline, getRowCountPipeline, debounceDelay
    }

  createTableDataMethods {
    viewTableRole, editRole, exportTableRole, sourceName, collection, useObjectIds,
    getRowsPipeline, getRowCountPipeline, getExportPipeline
    canEdit, canDelete, canExport, formSchema,
    makeFormDataFetchMethodRunFkt, makeSubmitMethodRunFkt, makeDeleteMethodRunFkt
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
  }

export default createTableDataAPI