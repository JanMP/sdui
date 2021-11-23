import React from 'react'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faPlus} from '@fortawesome/free-solid-svg-icons/faPlus'
import {faFileDownload} from '@fortawesome/free-solid-svg-icons/faFileDownload'
import {SearchInput} from "./SearchInput.coffee"
import {useTw} from '../config.coffee'

export DefaultHeader = ({
  loadedRowsCount, totalRowCount
  canSearch, search, onChangeSearch
  canExport, onExportTable, mayExport,
  canAdd, onAdd, mayEdit
}) ->

  tw = useTw()

  <div className={tw"flex justify-between"}>
    <div>{loadedRowsCount}/{totalRowCount}</div>
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
      <div>
        {
          if canExport
            <button
              className="icon-button"
              onClick={onExportTable} disabled={not mayExport}
            >
              <FontAwesomeIcon icon={faFileDownload}/>
            </button>
        }
        {
          if canAdd
            <button
              className="icon-button"
              style={marginLeft: '1rem'}
              onClick={onAdd} disabled={not mayEdit}
            >
              <FontAwesomeIcon icon={faPlus}/>
            </button>
        }
      </div>
    </div>
  </div>