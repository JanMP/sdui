import React, {useEffect, useState} from 'react'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
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

  <>
    <div className="default-header">
      {
        if totalRowCount
          <div className="row-count">{loadedRowCount}/{totalRowCount}</div>
        else
          <div className="row-count"/>
      }
      <div className="middle-container">
        {
          if canSort
            <div className="sort-container">
              <SortSelect {{
                listSchemaBridge
                sortColumn, sortDirection, onChangeSort
              }...}/>
            </div>
        }
        {
          if canSearch
            <div className="search-container">
              <SearchInput
                value={search}
                onChange={onChangeSearch}
              />
            </div>
        }
        {
          if canUseQueryEditor
            <button
              className="query-editor-toggle | icon secondary"
              onClick={toggleQueryEditor} disabled={not true}
            >
              <FontAwesomeIcon icon={faFilter}/>
            </button>
        }
      </div>
      <div className="buttons-container">
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
  </>