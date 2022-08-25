import React, {useEffect, useState} from 'react'
import {FontAwesomeIcon} from '@fortAwesome/react-fontawesome'
import {faPlus} from '@fortawesome/free-solid-svg-icons/faPlus'
import {faFileDownload} from '@fortawesome/free-solid-svg-icons/faFileDownload'
import {faFilter} from '@fortawesome/free-solid-svg-icons/faFilter'
import {SearchInput} from './SearchInput.coffee'
import {SortSelect} from './SortSelect.coffee'
import {QueryEditor} from '../query-editor/QueryEditor.coffee'


###*
  @typedef {import("../interfaces").DataTableHeaderOptions} DataTableHeaderOptions
  ###
###*
  @type {(options: DataTableHeaderOptions) => React.FC}
  ###
export DefaultHeader = ({
  listSchemaBridge
  loadedRowCount, totalRowCount
  canSearch, search, onChangeSearch
  canUseQueryEditor, onChangeQueryUiObject
  canExport, mayExport, onExportTable,
  canAdd, mayAdd, onAdd
  canSort, sortColumn, sortDirection, onChangeSort
  AdditionalHeaderButtonsLeft = -> null
  AdditionalHeaderButtonsRight = -> null
}) ->


  [showQueryEditor, setShowQueryEditor] = useState false
  [rule, setRule] = useState null

  toggleQueryEditor = -> setShowQueryEditor (x) -> not x

  useEffect ->
    unless showQueryEditor
      setRule null
      onChangeQueryUiObject null
  , [showQueryEditor]

  onChangeRule = (newRule) ->
    setRule newRule
    onChangeQueryUiObject newRule

  <div>
    <div className="flex justify-between p-2 border-b-2 border-secondary-200 flex-wrap gap-2">
      {
        if totalRowCount
          <div className="flex-grow">{loadedRowCount}/{totalRowCount}</div>
        else
          <div className="h-0 basis-0 flex-grow"/>
      }
      <div className="grow-[20] flex-shrink max-w-[40rem] flex-wrap flex justify-between gap-2">
        {
          if canSort
            <div className="flex-grow basis-[9rem] min-w-[9rem]">
              <SortSelect {{
                listSchemaBridge
                sortColumn, sortDirection, onChangeSort
              }...}/>
            </div>
        }
        {
          if canSearch
            <div className="flex-grow basis-[9rem] min-w-[9rem]">
              <SearchInput
                value={search}
                onChange={onChangeSearch}
              />
            </div>
        }
        {
          if canUseQueryEditor
            <button
              className="icon secondary"
              onClick={toggleQueryEditor} disabled={not true}
            >
              <FontAwesomeIcon icon={faFilter}/>
            </button>
        }
      </div>
      <div className="flex-shrink flex-grow text-right">
        <div className="children:m-1">
          <AdditionalHeaderButtonsLeft/>
          {
            if canExport
              <button
                className="primary icon"
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
          <AdditionalHeaderButtonsRight/>
        </div>
      </div>
    </div>
    <div className="h-full overflow-visible">
      {
        if showQueryEditor
          <QueryEditor
            bridge={listSchemaBridge}
            rule={rule}
            onChange={onChangeRule}
          />
      }
    </div>
  </div>