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


  toggleQueryEditor = -> setShowQueryEditor (x) -> not x

  useEffect ->
    unless queryUiObject?
      onChangeQueryUiObject null
  , [queryUiObject]


  hasEffectiveQueryUiObject = queryUiObject?.content?.length > 0

  <>
    <div
      ref={header}
      className="flex justify-content-between flex-wrap gap-2 p-2 p-card"
    >
      <div className="flex-order-0 flex-grow-0 p-2 text-base">
        {if totalRowCount then "#{loadedRowCount}/#{totalRowCount}" else null}
      </div>
      <div
        className="flex-order-2 flex-1 flex justify-content-center gap-2
          #{if width < 780 then 'flex-column' else 'flex-row'}
        "
      >
        {
          if canSort
            <SortSelect {{
              listSchemaBridge
              sortColumn, sortDirection, onChangeSort
            }...}/>
        }
        {
          if canSearch
            <SearchInput
              value={search}
              onChange={onChangeSearch}
            />
        }
        {
          if canUseQueryEditor
            <div>
              <Button
                icon="pi pi-filter"
                rounded text
                severity={if hasEffectiveQueryUiObject then 'warning' else 'secondary'}
                onClick={toggleQueryEditor} disabled={not true}
              />
            </div>
        }
      </div>
      <div
        className="flex justify-content-end #{if width < 900 then 'flex-order-1 w-9' else 'flex-order-3'}"
      >
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