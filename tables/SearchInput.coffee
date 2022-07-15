import React, {useState, useEffect} from 'react'
import {useDebounce} from '@react-hook/debounce'
import processSearchInput from '../common/processSearchInput.coffee'

export SearchInput = ({value, onChange, className = 'search-input'}) ->

  [showWarning, setShowWarning] = useState false
  [displayValue, setDisplayValue] = useState value
  [debouncedValue, setDebouncedValue] = useDebounce value, 500

  useEffect ->
    onChange debouncedValue
  , [debouncedValue]
  
  handleSearchChange = (newValue) ->
    setShowWarning (processSearchInput newValue)?.warn

    setDebouncedValue newValue
    setDisplayValue newValue


  <input
    placeholder="Suchen..."
    className={'search-input' + if showWarning then ' search-input--warn' else ''}
    type="text"
    value={displayValue}
    onChange={(e) -> handleSearchChange e.target.value}
  />