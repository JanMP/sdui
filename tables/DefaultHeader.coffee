import React, {useEffect, useState, useRef} from 'react'
import {SearchInput} from './SearchInput.coffee'
import {SortSelect} from './SortSelect.coffee'
import {QueryEditorModal} from '../query-editor/QueryEditorModal.coffee'
import useSize from '@react-hook/size'
import {Button} from 'primereact/button'
import {Toolbar} from 'primereact/toolbar'
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
  
  # workaround until we can use container queries
  toolbarRef = useRef null
  [width, height] = useSize toolbarRef


  toggleQueryEditor = -> setShowQueryEditor (x) -> not x

  useEffect ->
    unless queryUiObject?
      onChangeQueryUiObject null
  , [queryUiObject]

  hasEffectiveQueryUiObject = queryUiObject?.content?.length > 0

  pt =
    start:
      className: "flex-order-0"
    center:
      className:
        switch
          when width < 600 then "flex-grow-1 flex-order-2 flex-wrap gap-2"
          when width < 655 then "flex-grow-1 flex-order-2 gap-2"
          else "flex-grow-1 flex-order-1 gap-2"
    end:
      className:
        switch
          when width < 655 then "flex-order-1"
          else "flex-order-2"

  startContent =
    if totalRowCount then <span>{loadedRowCount}/{totalRowCount}</span>

  centerContent =
    <>
        {if canSort then <SortSelect {{listSchemaBridge,sortColumn, sortDirection, onChangeSort}...}/>}
        {if canSearch then <SearchInput value={search} onChange={onChangeSearch}/>}
    </>
    
  endContent =
    <>
      {
        if canUseQueryEditor
          <Button
            icon="pi pi-filter"
            rounded text
            severity={if hasEffectiveQueryUiObject then 'warning' else 'secondary'}
            onClick={toggleQueryEditor} disabled={not true}
          />
        }
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
    </>


  <div ref={toolbarRef}>
    <Toolbar start={startContent} center={centerContent} end={endContent} pt={pt}/>
    <QueryEditorModal
      bridge={queryEditorSchemaBridge}
      rule={queryUiObject}
      onChangeRule={onChangeQueryUiObject}
      isOpen={showQueryEditor}
      setIsOpen={setShowQueryEditor}
    />
  </div>