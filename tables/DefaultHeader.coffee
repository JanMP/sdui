import React from 'react'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faPlus} from '@fortAwesome/free-solid-svg-icons/faPlus'
import {faFileDownload} from '@fortAwesome/free-solid-svg-icons/faFileDownload'
import {SearchInput} from './SearchInput.coffee'
import {SortSelect} from './SortSelect.coffee'


###*
  @typedef {import("../interfaces").DataTableHeaderOptions} DataTableHeaderOptions
  ###
###*
  @type {(options: DataTableHeaderOptions) => JSX.Element}
  ###
export DefaultHeader = ({
  listSchemaBridge
  loadedRowCount, totalRowCount
  canSearch, search, onChangeSearch
  canExport, mayExport, onExportTable,
  canAdd, mayAdd, onAdd
  sortColumn, sortDirection, onChangeSort
}) ->

  <div className="flex justify-between p-4 border-b-4 border-secondary-200 flex-wrap gap-2">
    <div className="flex-grow">{loadedRowCount}/{totalRowCount}</div>
    {
      if true
        <div className="flex-grow">
          <SortSelect {{
            listSchemaBridge
            sortColumn, sortDirection, onChangeSort
          }...}/>
        </div>
    }
    {
      if canSearch
        <div className="flex-grow">
          <SearchInput
            value={search}
            onChange={onChangeSearch}
          />
        </div>
    }
    <div className="flex-shrink flex-grow-0 text-right">
      <div className="children:m-1">
        {
          if canExport
            <button
              className="icon"
              onClick={onExportTable} disabled={not mayExport}
            >
              <FontAwesomeIcon icon={faFileDownload}/>
            </button>
        }
        {
          if canAdd
            <button
              className="primary icon"
              onClick={onAdd} disabled={not mayAdd}
            >
              <FontAwesomeIcon icon={faPlus}/>
            </button>
        }
      </div>
    </div>
  </div>