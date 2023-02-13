import React, {useState, useEffect} from 'react'
import {useDebounce} from '@react-hook/debounce'
import processSearchInput from '../common/processSearchInput.coffee'
import {InputText} from 'primereact/inputtext'
import classname from 'classname'

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


  <span className="p-input-icon-right">
    <i
      className={if showWarning then "pi pi-exclamation-triangle" else"pi pi-search"}
    />
    <InputText
      className={classname 'p-invalid': showWarning}
      value={displayValue}
      onChange={(e) -> handleSearchChange e.target.value}
    />
  </span>