import xor from 'lodash/xor';
import React, { useState, useEffect, useRef, useCallback } from 'react';
import { HTMLFieldProps, connectField, filterDOMProps } from 'uniforms';
import setErrorClass from './setErrorClass';
import ReactSelect from 'react-select';
import isEqual from 'lodash/isEqual';

const base64: typeof btoa =
  typeof btoa !== 'undefined' ? btoa : x => Buffer.from(x).toString('base64');
const escape = (x: string) => base64(encodeURIComponent(x)).replace(/=+$/, '');

export type SelectFieldProps = HTMLFieldProps<
  string | string[],
  HTMLDivElement,
  {
    allowedValues?: string[];
    checkboxes?: boolean;
    disableItem?: (value: string) => boolean;
    inputRef?: Ref<HTMLSelectElement>;
    transform?: (value: string) => string;
  }
>;

function Select({
  allowedValues,
  checkboxes,
  disabled,
  fieldType,
  id,
  inputRef,
  label,
  name,
  onChange,
  placeholder,
  readOnly,
  disableItem,
  transform,
  value,
  ...props
}: SelectFieldProps) {
  
  const multiple = fieldType === Array;
  const selectRef = useRef(null);
  const [oldValue, setOldValue] = useState(null)

  const optionFromValue = useCallback((value) => {
    return {
      key: value,
      value: value,
      label: transform ? transform(value) : value
    };
  })

  const onOptionChange = useCallback((value) => {
    const result = (multiple ? value.map(v => v.value) : value.value);
    onChange(result);
  }, [multiple])

  useEffect(() => {
    if (isEqual(value, oldValue)) {return}
    setOldValue(value)
    selectRef.current?.setValue(multiple ? value.map(optionFromValue) : optionFromValue(value));
  }, [ value ]);

  return (
    <div { ...filterDOMProps(props) } className={ (checkboxes && setErrorClass(props)) || "" }>
      { label && <label htmlFor={ id }>{ label }</label> }
      { checkboxes ? (
        allowedValues!.map(item => (
          <div key={ item }>
            <input
              checked={
                fieldType === Array ? value!.includes(item) : value === item
              }
              disabled={ disableItem?.(item) ?? disabled }
              id={ `${id}-${escape(item)}` }
              name={ name }
              onChange={ () => {
                if (!readOnly) {
                  onChange(fieldType === Array ? xor([ item ], value) : item);
                }
              } }
              type="checkbox"
            />

            <label htmlFor={ `${id}-${escape(item)}` }>
              { transform ? transform(item) : item }
            </label>
          </div>
        ))
      ) : (
        <ReactSelect
          ref={ selectRef }
          disabled={ disabled }
          isMulti={ multiple }
          isInvalid={ props.error != null }
          onOptionChange={ onOptionChange }
          options={ allowedValues?.map(optionFromValue) }
          themeConfig={{control: {padding: "0 0.75rem", minHeight: '32px'}}}
        />
      ) }
    </div>
  );
}

export default connectField(Select, { kind: 'leaf' });
