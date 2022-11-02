import React, {useEffect, useState, useRef} from 'react'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faPlus} from '@fortawesome/free-solid-svg-icons/faPlus'
import {faFileDownload} from '@fortawesome/free-solid-svg-icons/faFileDownload'
import {faFilter} from '@fortawesome/free-solid-svg-icons/faFilter'
import {SearchInput} from './SearchInput.coffee'
import {SortSelect} from './SortSelect.coffee'
import {QueryEditorModal} from '../query-editor/QueryEditorModal.coffee'
import useSize from '@react-hook/size'


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
  
  # we do this with js because of some weird interaction of react-virtualized and react-select
  # when the react-select is inside a div with style container-type: inline-size
  # (react-virtual will draw over the menu of react-select)
  header = useRef null
  [width, height] = useSize header
  widthClass =
    switch
      when width < 440 then 'four-rows'
      when width < 550 then 'two-rows'
      else ''

  toggleQueryEditor = -> setShowQueryEditor (x) -> not x

  useEffect ->
    console.log queryUiObject
    unless queryUiObject?
      onChangeQueryUiObject null
  , [queryUiObject]

  hasEffectiveQueryUiObject = queryUiObject?.content?.length > 0

  <>
    <div ref={header} className="default-header #{widthClass}">
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
            <div className="query-editor-toggle-container">
              <button
                className="icon #{if hasEffectiveQueryUiObject then 'warning' else 'secondary'}"
                onClick={toggleQueryEditor} disabled={not true}
              >
                <FontAwesomeIcon icon={faFilter}/>
              </button>
            </div>
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