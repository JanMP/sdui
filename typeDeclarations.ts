import SimpleSchema2Bridge from 'uniforms-bridge-simple-schema-2'
import {Mongo} from 'meteor/mongo'
import SimpleSchema from 'simpl-schema'
import { createTableDataAPI } from './sdui-server'
import {FC} from React

export interface RoleObject {
  role:  string | Array<string>
  scope?: string
  forAnyScope?: boolean
}

export type Role = string | Array<string> | RoleObject | ((id: string) => boolean)

export interface createTableDataAPIParams {
  sourceName: string
  sourceSchema: SimpleSchema
  collection: Mongo.Collection<object>
  useObjectIds?: boolean
  listSchema?: SimpleSchema
  formSchema?: SimpleSchema
  queryEditorSchema?: SimpleSchema
  canEdit?: boolean
  canSearch?: boolean
  canUseQueryEditor?: boolean
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
  queryEditorSchemaBridge: SimpleSchema2Bridge
  rowsCollection: Mongo.Collection
  rowCountCollection: Mongo.Collection
  canEdit?: boolean
  canSearch?: boolean
  canUseQueryEditor?: boolean
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

export declare function createTableDataAPI(options: createTableDataAPIParams): createTableDataAPIReturn


// This is for additional options we can shove into our Components
export interface additionalDataTableOptions {
  onDelete?: ({id}: {id: string}) => Promise<any>
  onRowClick?: ({rowData, index}: {rowData: any, index: number}) => void
  autoFormChildren?: [any]
  formDisabled?: boolean
  formReadOnly?: boolean
  loadEditorData?: ({id}: {id: string}) => Promise<any>
  queryUiObject?: object
}

export type DataTableOptions = createTableDataAPIReturn & additionalDataTableOptions

export interface additionalDataTableDisplayOptions {
  rows: [any]
  totalRowCount: number
  loadMoreRows: ({startIndex, stopIndex}: {startIndex: number, stopIndex: number}) => Promise<any>
  sortColumn: string
  sortDirection: 'ASC' | 'DESC'
  onChangeSort: ({sortColumn, sortDirection}: {sortColumn: string, sortDirection: 'ASC' | 'DESC'}) => void
  search: 'string'
  onChangeSearch: (searchString: string) => void
  onDelete: ({id}: {id: string}) => Promise<any>
  onChangeQueryUiObject: (queryUiObject: object) => void 
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
  listSchemaBridge: SimpleSchema2Bridge
  queryEditorSchemaBridge: SimpleSchema2Bridge
  loadedRowCount: number
  totalRowCount: number
  canSearch?: boolean
  search?: string
  onChangeSearch?: (searchString: string) => void
  canUseQueryEditor?: boolean
  queryUiObject?: object
  onChangeQueryUiObject: (queryUiObject: object) => void
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
export declare function MeteorTableDataHandler(options: MeteorTableDataHandlerOptions): FC