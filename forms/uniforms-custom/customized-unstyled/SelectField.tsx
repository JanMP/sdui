import isEqual from 'lodash/isEqual';
import xor from 'lodash/xor';
import React, { useState, useEffect, useRef, useCallback, Ref } from 'react';
import ReactSelect, {OptionProps} from 'react-select';
import { HTMLFieldProps, connectField, filterDOMProps } from 'uniforms';
import setClassNamesForProps from './setClassNamesForProps';
import {useTranslation} from 'react-i18next'
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
  hasFloatingLabel?: boolean
  theme?: any;
  styles?: any
  isSearchable?: boolean
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
  sdTable,
  styles,
  theme,
  isSearchable,
  ...props
}: SelectFieldProps) {
  
  const {t} = useTranslation()
  
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
    const result = multiple
      ? value.map((v: { value: any }) => v.value)
      : value.value;
    onChange(result);
  }


  useEffect(() => {
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
      className={(checkboxes && setClassNamesForProps(props)) || ''}
    >
      {label && !props.hasFloatingLabel && <label htmlFor={id}>{t(label)}</label>}
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
            {label && props.hasFloatingLabel && <label htmlFor={id}>{t(label)}</label>}
          </div>
        ))
      ) : (
        <ReactSelect
          className="react-select"
          classNamePrefix="react-select"
          ref={selectRef}
          isDisabled={disabled}
          isMulti={multiple}
          components={components}
          // @ts-ignore
          onChange={onOptionChange}
          options={allowedValues?.map(optionFromValue)}
          styles={styles}
          theme={theme}
          isSearchable={isSearchable ?? true}
        />
      )}
    </div>
  );
}

export default connectField<SelectFieldProps>(Select, { kind: 'leaf' });
