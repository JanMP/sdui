import cloneDeep from 'lodash/cloneDeep';
import React from 'react';
import {
  HTMLFieldProps,
  connectField,
  filterDOMProps,
  joinName,
  useField,
} from 'uniforms';
import { Button } from 'primereact/button';

export type ListAddFieldProps = HTMLFieldProps<
  unknown,
  HTMLSpanElement,
  { initialCount?: number }
>;

function ListAdd({
  disabled,
  initialCount,
  name,
  readOnly,
  value,
  ...props
}: ListAddFieldProps) {
  const nameParts = joinName(null, name);
  const parentName = joinName(nameParts.slice(0, -1));
  const parent = useField<
    { initialCount?: number; maxCount?: number },
    unknown[]
  >(parentName, { initialCount }, { absoluteName: true })[0];

  const limitNotReached =
    !disabled && !(parent.maxCount! <= parent.value!.length);

  function onAction(event: React.KeyboardEvent | React.MouseEvent) {
    if (
      limitNotReached &&
      !readOnly &&
      (!('key' in event) || event.key === 'Enter')
    ) {
      parent.onChange(parent.value!.concat([cloneDeep(value)]));
    }
  }

  return (
    // @ts-ignore
    <Button
      {...filterDOMProps(props)}
      onClick={onAction}
      icon="pi pi-plus"
      rounded
      text
    />
  );
}

export default connectField<ListAddFieldProps>(ListAdd, {
  initialValue: false,
  kind: 'leaf',
});
