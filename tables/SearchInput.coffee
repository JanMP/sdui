import React, {useState, useEffect} from 'react'
import {useDebounce} from '@react-hook/debounce'
import {useTw} from '../config.coffee'

export SearchInput = ({value, onChange, className}) ->

  tw = useTw()

  className ?= tw"max-w-[10rem] min-w-[5rem]"

  [isValid, setIsValid] = useState true
  [displayValue, setDisplayValue] = useState value
  [debouncedValue, setDebouncedValue] = useDebounce value, 500

  useEffect ->
    onChange debouncedValue
  , [debouncedValue]
  
  handleSearchChange = (newValue) ->
    try
      new RegExp newValue unless newValue is ''
      setIsValid true
      setDebouncedValue newValue
    catch error
      setIsValid false
    finally
      setDisplayValue newValue

  <input
    className={className}
    type="text"
    value={displayValue}
    onChange={(e) -> handleSearchChange e.target.value}
  />