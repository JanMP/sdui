import SimpleSchema2Bridge from 'uniforms-bridge-simple-schema-2'
import {Mongo} from 'meteor/mongo'
import SimpleSchema from 'simpl-schema'
import {FC} from React


export interface createTableDataAPIParams {
  sourceName: string
  sourceSchema: SimpleSchema
  collection: Mongo.Collection
  useObjectIds?: boolean
  listSchema?: SimpleSchema
  formSchema?: SimpleSchema
  canEdit?: boolean
  canSearch?: boolean
  canSort?: boolean
  canAdd?: boolean
  canDelete?: boolean
  canExport?: boolean
  viewTableRole?: string | Array<string>
  editRole?: string  | Array<string>
  addRole?: string  | Array<string>
  deleteRole?: string  | Array<string>
  exportTableRole?: string | Array<string>
  query?: object
  initialSortColumn?: string
  initialSortDirection?: 'ASC' | 'DESC'
  perLoad?: number
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
    }) => (options: {id: string}) => Mongo.Cursor
  makeSubmitMethodRunFkt?:
    (options: {
      collection: Mongo.Collection
      transFormIdToMongo: (id: any) => any
      transFormIdToMiniMongo: (id: any) => any
    }) => (options: {data: object, id: string}) => void
  makeDeleteMethodRunFkt?:
    (options: {
      collection: Mongo.Collection
      transFormIdToMongo: (id: any) => any
      transFormIdToMiniMongo: (id: any) => any
    }) => (options: {id: string}) => void
  debounceDelay?: number
  observers?: Array<any>
  setupNewItem?: () => object
  showRowCount?: boolean
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
  canSort?: boolean
  canAdd?: boolean
  canDelete?: boolean
  deleteConfirmation?: string
  canExport?: boolean
  viewTableRole?: string | Array<string>
  editRole?: string | Array<string>
  addRole?: string | Array<string>
  deleteRole?: string | Array<string>
  exportTableRole?: string | Array<string>
  setupNewItem?: () => object
  onSubmit?: (object) => any
  onChangeField?: ({_id: string, changeData: object}) => any
  query?: object
  initialSortColumn?: string
  initialSortDirection?: 'ASC' | 'DESC'
  showRowCount?: boolean
  perLoad: number
}

interface additionalDataTableOptions {
  onDelete?: ({id: string}) => Promise<any>
  onRowClick?: ({rowData, index}: {rowData: any, index: number}) => void
  autoFormChildren?: [any]
  formDisabled?: boolean
  formReadOnly?: boolean
  loadEditorData?: ({id: string}) => Promise<any>
}

export type DataTableOptions = createTableDataAPIReturn & additionalDataTableOptions

export interface DataTableDisplayOptions {
  rows: [any]
  totalRowCount: number
  loadMoreRows: ({startIndex, stopIndex}: {startIndex: number, stopIndex: number}) => Promise<any>
  sortColumn: string
  sortDirection: 'ASC' | 'DESC'
  onChangeSort: ({sortColumn, sortDirection}: {sortColumn: string, sortDirection: 'ASC' | 'DESC'}) => void
  search: 'string'
  onChangeSearch: (searchString: string) => void
  onDelete: ({id}: {id: string}) => Promise<any>
}

export interface DataTableHeaderOptions {
  listSchemaBridge: object
  loadedRowCount: number
  totalRowCount: number
  canSearch?: boolean
  search?: string
  onChangeSearch?: (searchString: string) => void
  canExport?: boolean
  mayExport?: boolean
  onExportTable?: () => void
  canAdd?: boolean
  mayAdd?: boolean
  onAdd?: () => void
  canSort?: boolean
  sortColumn?: string
  sortDirection?: 'ASC' | 'DESC'
  onChangeSort:  ({sortColumn, sortDirection}: {sortColumn: string, sortDirection: 'ASC' | 'DESC'}) => void
  AdditionalButtonsLeft?: FC
  AdditionalButtonsRight?: FC
  // query?: object
  // onChangeQuery?: (query: object) => void
}