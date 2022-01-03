import isEqual from 'lodash/isEqual';
import xor from 'lodash/xor';
import React, { useState, useEffect, useRef, useCallback, Ref } from 'react';
import ReactSelect from 'react-select';
import { HTMLFieldProps, connectField, filterDOMProps } from 'uniforms';

import setErrorClass from './setErrorClass';

const base64: typeof btoa =
  typeof btoa === 'undefined'
    ? /* istanbul ignore next */ x => Buffer.from(x).toString('base64')
    : btoa;
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
    components?: any;
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
  required,
  disableItem,
  transform,
  value,
  components,
  ...props
}: SelectFieldProps) {
  const multiple = fieldType === Array;
  const selectRef = useRef(null);
  const [oldValue, setOldValue] = useState(null);

  const optionFromValue = useCallback(
    value => {
      return {
        key: value,
        value,
        label: transform ? transform(value) : value,
      };
    },
    [transform],
  );

  const onOptionChange = (value: any) => {
    console.log('onOptionChange', value)
    const result = multiple
      ? value.map((v: { value: any }) => v.value)
      : value.value;
    onChange(result);
  }


  useEffect(() => {
    console.log('value Changed', value)
    // @ts-ignore
    setOldValue(value);
    if (isEqual(value, oldValue)) {
      return;
    }
    // @ts-ignore
    selectRef.current?.setValue(
      // @ts-ignore
      multiple ? value.map(optionFromValue) : optionFromValue(value),
    );
  }, [value]);

  return (
    <div
      {...filterDOMProps(props)}
      className={(checkboxes && setErrorClass(props)) || ''}
    >
      {label && <label htmlFor={id}>{label}</label>}
      {checkboxes ? (
        allowedValues!.map(item => (
          <div key={item}>
            <input
              checked={
                fieldType === Array ? value!.includes(item) : value === item
              }
              disabled={disableItem?.(item) ?? disabled}
              id={`${id}-${escape(item)}`}
              name={name}
              onChange={() => {
                if (!readOnly) {
                  onChange(fieldType === Array ? xor([item], value) : item);
                }
              }}
              type="checkbox"
            />

            <label htmlFor={`${id}-${escape(item)}`}>
              {transform ? transform(item) : item}
            </label>
          </div>
        ))
      ) : (
        <ReactSelect
          ref={selectRef}
          isDisabled={disabled}
          isMulti={multiple}
          components={components}
          // @ts-ignore
          onChange={onOptionChange}
          options={allowedValues?.map(optionFromValue)}
        />
      )}
    </div>
  );
}

export default connectField<SelectFieldProps>(Select, { kind: 'leaf' });
