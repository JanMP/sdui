import React, {useEffect} from 'react'
import {MeteorTableDataHandler} from './MeteorTableDataHandler.coffee'
import {connectField} from 'uniforms'
import {Dropdown} from 'primereact/dropdown'
import _ from 'lodash'

# TODO Get this to work

DisplayComponent = (value, onChange, selectOptions) -> (tableOptions) ->

  {getValue, getLabel, isMulti} = selectOptions ? {}

  isMulti ?= false

  options =
    tableOptions?.rows?.map (row) ->
      value: getValue row
      label: getLabel row


  valueOption = (_.find options, {value}) ? if value? then {value, label: "[#{value}]"}

  <div>
    {<pre>{JSON.stringify options , null, 2}</pre> if false}
    <Dropdown
      value={valueOption}
      onChange={(e) -> onChange e.value}
      options={options}
      onInputChange={tableOptions.onChangeSearch}
    />
  </div>


export SdDocumentSelect = ({value, onChange, dataOptions, selectOptions}) ->
  <MeteorTableDataHandler
    dataOptions={dataOptions}
    DisplayComponent={DisplayComponent value, onChange, selectOptions}
  />

export SdDocumentSelectField = connectField SdDocumentSelect, kind: 'leaf'
