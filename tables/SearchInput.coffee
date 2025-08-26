import React, {useState, useEffect} from 'react'
import {useDebounce} from '@react-hook/debounce'
import processSearchInput from '../common/processSearchInput.coffee'
import {InputText} from 'primereact/inputtext'
import {SplitButton} from 'primereact/splitbutton'
import classnames from 'classnames'

export SearchInput = ({value, onChange, canKnnSearch, isKnnSearch, onSetIsKnnSearch, className = 'search-input'}) ->

  canKnnSearch ?= false
  isKnnSearch ?= false
  onSetIsKnnSearch ?= () -> console.warn 'onSetIsKnnSearch not set'

  [showWarning, setShowWarning] = useState false
  [displayValue, setDisplayValue] = useState value
  [debouncedValue, setDebouncedValue] = useDebounce value, 1000

  useEffect ->
    onChange debouncedValue
  , [debouncedValue]

  useEffect ->
    setDisplayValue ''
    setDebouncedValue ''
  , [isKnnSearch]

  handleSearchChange = (newValue) ->
    setShowWarning warning = (processSearchInput newValue)?.warn
    setDisplayValue newValue
    setDebouncedValue newValue unless warning

  menuItems = [
    label: 'Text/RegEx Search'
    icon: 'pi pi-search'
    command: -> onSetIsKnnSearch false
  ,
    label: 'KNN Search'
    icon: 'pi pi-bolt'
    command: -> onSetIsKnnSearch true
  ]

  <div
    className="p-inputgroup"
  >
    <InputText
      className={classnames 'p-invalid': showWarning}
      value={displayValue}
      onChange={(e) -> handleSearchChange e.target.value}
      style={width: '100%'}
    />
    {
      if canKnnSearch
        <SplitButton
          icon={if isKnnSearch then "pi pi-bolt" else "pi pi-search"}
          buttonClassName="p-button-outlined"
          severity="secondary"
          model={menuItems}
        />
      else
        <span className="p-inputgroup-addon">
          <i className={if showWarning then "pi pi-exclamation-triangle" else"pi pi-search"}/>
        </span>
    }
  </div>