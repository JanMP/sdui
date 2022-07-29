import React, {useEffect} from 'react'
import {MeteorTableDataHandler} from './MeteorTableDataHandler.coffee'
import {connectField} from 'uniforms'
import Select from 'react-select'
import _ from 'lodash'

DisplayComponent = (value, onChange, selectOptions) -> (tableOptions) ->

  {getValue, getLabel, isMulti} = selectOptions ? {}

  isMulti ?= false

  options =
    tableOptions?.rows?.map (row) ->
      value: getValue row
      label: getLabel row


  valueOption = (_.find options, {value}) ? if value? then {value, label: "[#{value}]"}

  handleChange = (newValueOption) ->
    onChange newValueOption?.value

  <div>
    {<pre>{JSON.stringify options , null, 2}</pre> if false}
    <Select
      value={valueOption}
      onChange={handleChange}
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
