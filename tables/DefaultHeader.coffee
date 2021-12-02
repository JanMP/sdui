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

  <div className={tw"flex justify-between px-4"}>
    <div>{loadedRowCount}/{totalRowCount}</div>
    <div>
      <div className={tw"text-center"}>
        {
          if canSearch
            <SearchInput
              size="small"
              value={search}
              onChange={onChangeSearch}
            />
        }
      </div>
    </div>
    <div>
      <div className={tw"children:ml-2"}>
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