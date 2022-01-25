import React from 'react'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faPlus} from '@fortawesome/free-solid-svg-icons/faPlus'
import {faFileDownload} from '@fortawesome/free-solid-svg-icons/faFileDownload'
import {SearchInput} from "./SearchInput.coffee"
import {useTw} from '../config.coffee'

export DefaultHeader = ({
  loadedRowCount, totalRowCount
  canSearch, search, onChangeSearch
  canExport, onExportTable, mayExport,
  canAdd, onAdd, mayEdit
}) ->

  tw = useTw()

  <div className={tw"flex justify-between p-4 border-b-4 border-secondary-200 flex-wrap gap-2"}>
    <div className={tw"flex-grow"}>{loadedRowCount}/{totalRowCount}</div>
    <div className={tw"flex-grow"}>
        {
          if canSearch
            <SearchInput
              value={search}
              onChange={onChangeSearch}
            />
        }
    </div>
    <div className={tw"flex-shrink flex-grow-0 text-right"}>
      <div className={tw"children:m-1"}>
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
              onClick={onAdd} disabled={not mayEdit}
            >
              <FontAwesomeIcon icon={faPlus}/>
            </button>
        }
      </div>
    </div>
  </div>