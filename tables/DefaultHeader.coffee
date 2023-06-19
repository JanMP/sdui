import React, {useEffect, useState, useRef} from 'react'
import {SearchInput} from './SearchInput.coffee'
import {SortSelect} from './SortSelect.coffee'
import {QueryEditorModal} from '../query-editor/QueryEditorModal.coffee'
import useSize from '@react-hook/size'
import {Button} from 'primereact/button'
import * as types from '../typeDeclarations'


###*
  @type {types.DefaultHeader}
  ###
export DefaultHeader = ({
  listSchemaBridge
  queryEditorSchemaBridge
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
              <Button
                icon="pi pi-filter"
                rounded text
                severity={if hasEffectiveQueryUiObject then 'warning' else 'secondary'}
                onClick={toggleQueryEditor} disabled={not true}
              />
            </div>
        }
      </div>
      <div className="buttons-container">
        <AdditionalHeaderButtonsLeft/>
        {
          if canExport
            <Button
              icon="pi pi-download"
              severity="secondary"
              rounded text
              onClick={onExportTable}
              disabled={not mayExport}
            />
        }
        {
          if canAdd
            <Button
              icon="pi pi-plus"
              rounded text
              onClick={onAdd} disabled={not mayAdd}
            />
        }
        <AdditionalHeaderButtonsRight/>
      </div>
    </div>
    <QueryEditorModal
      bridge={queryEditorSchemaBridge}
      rule={queryUiObject}
      onChangeRule={onChangeQueryUiObject}
      isOpen={showQueryEditor}
      setIsOpen={setShowQueryEditor}
    />
  </>