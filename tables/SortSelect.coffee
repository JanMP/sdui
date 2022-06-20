import React, {useEffect} from 'react'
import Select from 'react-select'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faArrowDownAZ} from '@fortAwesome/free-solid-svg-icons/faArrowDownAZ'
import {faArrowUpZA} from '@fortAwesome/free-solid-svg-icons/faArrowUpZA'
import {faUpDown} from '@fortAwesome/free-solid-svg-icons/faUpDown'



export SortSelect = ({listSchemaBridge, sortColumn, sortDirection, onChangeSort}) ->

  schema = listSchemaBridge?.schema
  columnKeys = schema._firstLevelSchemaKeys

  optionForKey = (key) ->
    value: key
    label: schema._schema[key]?.label

  options = columnKeys.map optionForKey
  valueOption = optionForKey sortColumn

  icon = switch sortDirection
    when'ASC' then faArrowDownAZ
    when 'DESC' then faArrowUpZA
    else faArrowDownAZ

  changeValue = ({value}) ->
    onChangeSort
      sortColumn: value
      sortDirection: sortDirection ? 'ASC'

  toggleSortDirection = (e) ->
    onChangeSort
      sortColumn: sortColumn ? columnKeys?[0]
      sortDirection: if sortDirection is 'ASC' then 'DESC' else 'ASC'

  IndicatorsContainer = ->
    <div
      className="p-[7px] text-center"
      onMouseDown={(e) -> e.stopPropagation()}
    >
      <FontAwesomeIcon className="text-xl z-10 #{if sortColumn? then 'text-gray-600' else 'text-gray-400'}" icon={icon} onClick={toggleSortDirection}/>
    </div>
    
  
  <Select
    className="sort-select-container w-full"
    classNamePrefix="sort-select"
    components={{IndicatorsContainer}}
    value={valueOption}
    options={options}
    onChange={changeValue}
  />