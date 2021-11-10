import React, {useEffect, useRef, useState} from 'react'
import { Select } from 'react-functional-select'
import isEqual from 'lodash/isEqual'

# CHECK if we should rather get rid of this and use react-select directly
export default ControlledSelect = ({value, options, onChange, disabled, multiple, themeConfig}) ->
  
  themeConfig ?=
    control:
      padding: '0 0'
      minHeight: '32px'

  selectRef = useRef null
  [oldValue, setOldValue] = useState null

  # useEffect ->
  #   unless isEqual value, oldValue
  #     setOldValue value
  #     selectRef.current?.setValue value
  # , [value]


  <Select
    value={value}
    ref={selectRef}
    disabled={disabled}
    isMulti={multiple}
    onOptionChange={onChange}
    options={options}
    themeConfig={themeConfig}
  />
