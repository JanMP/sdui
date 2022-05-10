import SimpleSchema2Bridge from 'uniforms-bridge-simple-schema-2'
import {Mongo} from 'meteor/mongo'
import SimpleSchema from 'simpl-schema'


export interface createTableDataAPIParams {
  sourceName: string
  sourceSchema: SimpleSchema
  collection: Mongo.Collection
  useObjectIds?: boolean
  listSchema?: SimpleSchema
  formSchema?: SimpleSchema
  canEdit?: boolean
  canSearch?: boolean
  canAdd?: boolean
  canDelete?: boolean
  canExport?: boolean
  viewTableRole?: string
  editRole?: string
  exportTableRole?: string
  getPreSelectPipeline?: ({pub}?: {pub: object}) => Array<Object>
  getProcessorPipeline?: ({pub}?: {pub: object}) => Array<Object>
  getRowsPipeline?:
    (_: {
        pub: object,
        search: string,
        query?: Mongo.Query,
        sort?: Mongo.SortSpecifier
        limit?: number
        skip?: number}) => Array<object>
  getRowCountPipeline?:
    (options: {
      pub: object,
      search: string,
      query?: Mongo.Query}) => Array<object>
  getExportPipeline?:
    (options: {
      search: string,
      query?: Mongo.Query,
      sort?: Mongo.SortSpecifier}) => Array<object>
  makeFormDataFetchMethodRunFkt?:
    (options: {
      collection: Mongo.Collection
      transFormIdToMongo: (id: any) => any
      transFormIdToMiniMongo: (id: any) => any
    }) => ({id: string}) => Mongo.Cursor
  makeSubmitMethodRunFkt?:
    (options: {
      collection: Mongo.Collection
      transFormIdToMongo: (id: any) => any
      transFormIdToMiniMongo: (id: any) => any
    }) => ({data: object, id: string}) => void
  makeDeleteMethodRunFkt?:
    (options: {
      collection: Mongo.Collection
      transFormIdToMongo: (id: any) => any
      transFormIdToMiniMongo: (id: any) => any
    }) => ({id: string}) => void
  debounceDelay?: number
  observers?: Array<any>
  setupNewItem?: () => object
  checkDisableEditForRow?: boolean
  checkDisableDeleteForRow?: boolean 
}
export interface createTableDataAPIReturn {
  sourceName: string
  listSchemaBridge: SimpleSchema2Bridge
  formSchemaBridge: SimpleSchema2Bridge
  rowsCollection: Mongo.Collection
  rowCountCollection: Mongo.Collection
  canEdit?: boolean
  canSearch?: boolean
  canAdd?: boolean
  canDelete?: boolean
  deleteConfirmation?: string
  canExport?: boolean
  viewTableRole?: string
  editRole?: string
  exportTableRole?: string
  setupNewItem?: () => object
  onSubmit?: (object) => any
  onChangeField?: ({_id: string, changeData: object}) => any
}

interface additionalDataTableOptions {
  query?: any
  perLoad?: number
  onDelete?: ({id: string}) => Promise<any>
  onRowClick?: ({rowData, index}: {rowData: any, index: number}) => void
  autoFormChildren?: [any]
  formDisabled?: boolean
  formReadOnly?: boolean
  loadEditorData?: ({id: string}) => Promise<any>
}

export type DataTableOptions = createTableDataAPIReturn & additionalDataTableOptions

export interface DataTabpeDisplayOptions {
  rows: [any]
  totalRowCount: number
  loadMoreRows: ({startIndex, stopIndex}: {startIndex: number, stopIndex: number}) => Promise<any>
  sortColumn: string
  sortDirection: 'ASC' | 'DESC'
  onCangeSort: ({sortColumn, sortDirection}: {sortColumn: string, sortDirection: 'ASC' | 'DESC'}) => void
  search: 'string'
  onChangeSearch: (searchString: string) => void
  onDelete: ({id}: {id: string}) => Promise<any>

}