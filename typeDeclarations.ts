import {Mongo} from 'meteor/mongo'
import {Schema} from 'meteor/janmp:sdui'
import {FC} from 'react'

export interface RoleObject {
  role:  string | Array<string>
  scope?: string
  forAnyScope?: boolean
}

export type Role = string | Array<string> | RoleObject | ((id: string) => boolean)

export interface SdAiSettings {
  embeddingModelSettings: object
  getEmbeddingContext: (params: {document: object}) => string
}

export interface createTableDataAPIParams {
  sourceName: string
  sourceSchema: Schema
  collection: Mongo.Collection<object>
  useObjectIds?: boolean
  listSchema?: Schema
  formSchema?: Schema
  canEdit?: boolean
  canSearch?: boolean
  canSort?: boolean
  canAdd?: boolean
  canDelete?: boolean
  canExport?: boolean
  viewTableRole?: Role
  editRole?: Role
  addRole?: Role
  deleteRole?: Role
  exportTableRole?: Role
  query?: object
  initialSortColumn?: string
  initialSortDirection?: 'ASC' | 'DESC'
  perLoad?: number
  getPreSelectPipeline?: ({pub}?: {pub: object}) => Promise<Array<Object> | null>
  getProcessorPipeline?: ({pub}?: {pub: object}) => Promise<Array<Object> | null>
  getRowsPipeline?:
    (_: {
        pub: object,
        search: string,
        query?: Mongo.Query<any>,
        sort?: Mongo.SortSpecifier
        limit?: number
        skip?: number}) => Array<object>
  getExportPipeline?:
    (options: {
      search: string,
      query?: Mongo.Query<any>,
      sort?: Mongo.SortSpecifier}) => Array<object>
  makeFormDataFetchMethodRunFkt?:
    (options: {
      collection: Mongo.Collection<any>
      transFormIdToMongo: (id: any) => any
      transFormIdToMiniMongo: (id: any) => any
    }) => (options: {id: string}) => Mongo.Cursor<any>
  makeSubmitMethodRunFkt?:
    (options: {
      collection: Mongo.Collection<any>
      transFormIdToMongo: (id: any) => any
      transFormIdToMiniMongo: (id: any) => any
    }) => (options: {data: object, id: string}) => void
  makeDeleteMethodRunFkt?:
    (options: {
      collection: Mongo.Collection<any>
      transFormIdToMongo: (id: any) => any
      transFormIdToMiniMongo: (id: any) => any
    }) => (options: {id: string}) => void
  noAutomaticObserver?: boolean
  debounceDelay?: number
  getObservers?:() => Array<any>
  setupNewItem?: () => object
  onSubmit?: (object) => any
  checkDisableEditForRow?: boolean
  checkDisableDeleteForRow?: boolean 
  usePubSub?: boolean
  sdAiSettings?: SdAiSettings
}
export interface createTableDataAPIReturn {
  sourceName: string
  listSchema: Schema
  formSchema: Schema
  rowsCollection: Mongo.Collection<any>
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
  onDelete?: ({id}: {id: string}) => Promise<any>
  onChangeField?: ({_id, changeData}: {_id: string, changeData: object}) => any
  query?: object
  initialSortColumn?: string
  initialSortDirection?: 'ASC' | 'DESC'
  perLoad: number
  usePubSub: boolean
}

export declare function createTableDataAPI(options: createTableDataAPIParams): createTableDataAPIReturn


// This is for additional options we can shove into our Components
export interface additionalDataTableOptions {
  onRowClick?: ({rowData, index}: {rowData: any, index: number}) => void
  autoFormChildren?: [any]
  formDisabled?: boolean
  formReadOnly?: boolean
  loadEditorData?: ({id}: {id: string}) => Promise<any>
}

export type DataTableOptions = createTableDataAPIReturn & additionalDataTableOptions

export interface additionalDataTableDisplayOptions {
  rows: [any]
  loadMoreRows: ({startIndex, stopIndex}: {startIndex: number, stopIndex: number}) => Promise<any>
  sortColumn: string
  sortDirection: 'ASC' | 'DESC'
  onChangeSort: ({sortColumn, sortDirection}: {sortColumn: string, sortDirection: 'ASC' | 'DESC'}) => void
  search: 'string'
  onChangeSearch: (searchString: string) => void
  onDelete: ({id}: {id: string}) => Promise<any>
  mayAdd?: boolean
  onAdd?: () => void
  mayDelete?: boolean
  mayEdit?: boolean
  mayExport?: boolean
  onExportTable?: () => void
  isLoading?: boolean
  overscanRowCount?: number
  customComponents: customComponents
}

export type DataTableDisplayOptions = DataTableOptions & additionalDataTableDisplayOptions

export declare function DataTableDisplayComponent(options: DataTableDisplayOptions): FC

export interface DataTableHeaderOptions {
  listSchema: Schema
  loadedRowCount: number
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
  AdditionalHeaderButtonsLeft?: FC
  AdditionalHeaderButtonsRight?: FC
  // query?: object
  // onChangeQuery?: (query: object) => void
}
export declare function DefaultHeader(options: DataTableHeaderOptions): FC

// TODO [TS] gather types of all implemented customComponent props
export type customComponents = {[key: string]: FC}

export interface MeteorTableDataHandlerOptions {
  dataOptions: DataTableOptions
  DisplayComponent: typeof DataTableDisplayComponent
  customComponents: customComponents
}
export declare function MeteorTableDataHandler(options: MeteorTableDataHandlerOptions): FC// Combined .d.ts file
