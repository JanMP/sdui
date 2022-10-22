import React, {useEffect, useState} from 'react'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faPlus} from '@fortawesome/free-solid-svg-icons/faPlus'
import {faFileDownload} from '@fortawesome/free-solid-svg-icons/faFileDownload'
import {faFilter} from '@fortawesome/free-solid-svg-icons/faFilter'
import {SearchInput} from './SearchInput.coffee'
import {SortSelect} from './SortSelect.coffee'
import {QueryEditorModal} from '../query-editor/QueryEditorModal.coffee'


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
  canUseQueryEditor, queryUiObject, onChangeQueryUiObject
  canExport, mayExport, onExportTable,
  canAdd, mayAdd, onAdd
  canSort, sortColumn, sortDirection, onChangeSort
  AdditionalHeaderButtonsLeft = -> null
  AdditionalHeaderButtonsRight = -> null
}) ->


  [showQueryEditor, setShowQueryEditor] = useState false


  toggleQueryEditor = -> setShowQueryEditor (x) -> not x

  useEffect ->
    console.log queryUiObject
    unless queryUiObject?
      onChangeQueryUiObject null
  , [queryUiObject]

  hasEffectiveQueryUiObject = queryUiObject?.content?.length > 0

  <>
    <div className="default-header">
      {
        if totalRowCount
          <div className="row-count">{loadedRowCount}/{totalRowCount}</div>
        else          <div className="row-count"/>
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
              className="icon #{if hasEffectiveQueryUiObject then 'warning' else 'secondary'}"
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
    <QueryEditorModal
      bridge={listSchemaBridge}
      rule={queryUiObject}
      onChangeRule={onChangeQueryUiObject}
      isOpen={showQueryEditor}
      setIsOpen={setShowQueryEditor}
    />
  </>