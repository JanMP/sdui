import React, {useState, useEffect} from 'react'
import {useDebounce} from '@react-hook/debounce'
import processSearchInput from '../common/processSearchInput.coffee'
import {InputText} from 'primereact/inputtext'
import classnames from 'classnames'

export SearchInput = ({value, onChange, className = 'search-input'}) ->

  [showWarning, setShowWarning] = useState false
  [displayValue, setDisplayValue] = useState value
  [debouncedValue, setDebouncedValue] = useDebounce value, 500

  useEffect ->
    onChange debouncedValue
  , [debouncedValue]
  
  handleSearchChange = (newValue) ->
    setShowWarning warning = (processSearchInput newValue)?.warn
    setDisplayValue newValue

    setDebouncedValue newValue unless warning


  <div
    className="p-inputgroup"
  >
    <InputText
      className={classnames 'p-invalid': showWarning}
      value={displayValue}
      onChange={(e) -> handleSearchChange e.target.value}
      style={width: '100%'}
    />
    <span className="p-inputgroup-addon">
      <i className={if showWarning then "pi pi-exclamation-triangle" else"pi pi-search"}/>
    </span>
  </div>