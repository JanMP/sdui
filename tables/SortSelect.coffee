import React, {useEffect} from 'react'
import {Dropdown} from 'primereact/dropdown'
import {Button} from 'primereact/button'

sortDirectionIcons =
  ASC: 'pi pi-sort-down'
  DESC: 'pi pi-sort-up'


export SortSelect = ({listSchemaBridge, sortColumn, sortDirection, onChangeSort}) ->

  schema = listSchemaBridge?.schema
  columnKeys = schema._firstLevelSchemaKeys

  sortColumnOptions =
    columnKeys.map (key) ->
      value: key
      label: schema._schema[key]?.label

  changeValue = ({value}) ->
    onChangeSort
      sortColumn: value
      sortDirection: sortDirection ? 'ASC'

  toggleSortDirection = ->
    onChangeSort
      sortColumn: sortColumn ? columnKeys?[0]
      sortDirection: if sortDirection is 'ASC' then 'DESC' else 'ASC'


  <div className="p-inputgroup">
    <Dropdown
      value={sortColumn}
      options={sortColumnOptions}
      onChange={changeValue}
    />
    <Button
      className="p-button-secondary"
      icon={sortDirectionIcons[sortDirection] ? 'pi pi-sort'}
      onClick={toggleSortDirection}
    />
  </div>