import React, {useEffect, useState, useRef} from 'react'
import {SearchInput} from './SearchInput.coffee'
import {SortSelect} from './SortSelect.coffee'
import useSize from '@react-hook/size'
import {Button} from 'primereact/button'
import {Toolbar} from 'primereact/toolbar'
import * as types from '../typeDeclarations'


###*
  @type {types.DefaultHeader}
  ###
export DefaultHeader = ({
  listSchema
  loadedRowCount
  canSearch, search, onChangeSearch
  canExport, mayExport, onExportTable,
  canAdd, mayAdd, onAdd
  canSort, sortColumn, sortDirection, onChangeSort
  AdditionalHeaderButtonsLeft = -> null
  AdditionalHeaderButtonsRight = -> null
}) ->

  
  # workaround until we can use container queries
  toolbarRef = useRef null
  [width, height] = useSize toolbarRef

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

  startContent = -> null

  centerContent =
    <>
        {if canSort then <SortSelect {{listSchema,sortColumn, sortDirection, onChangeSort}...}/>}
        {if canSearch then <SearchInput value={search} onChange={onChangeSearch}/>}
    </>
    
  endContent =
    <>
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
  </div>