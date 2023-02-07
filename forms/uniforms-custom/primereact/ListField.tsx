import React, { Children, cloneElement, isValidElement } from 'react';
import { HTMLFieldProps, connectField, filterDOMProps } from 'uniforms';
import ListAddField from './ListAddField';
import ListItemField from './ListItemField';
import {useTranslation} from 'react-i18next'

export type ListFieldProps = HTMLFieldProps<
unknown[],
HTMLUListElement,
{ initialCount?: number; itemProps?: object }
>;

function List({
  children = <ListItemField name="$" />,
  initialCount,
  itemProps,
  label,
  value,
  ...props
}: ListFieldProps) {
  
  const {t} = useTranslation()

  return (
    <ul {...filterDOMProps(props)} className="u-list-field">
      {label && (
        <div>
          <div className="u-list-field-header">
            <div>{t(label)}</div>
            <div>
              <ListAddField initialCount={initialCount} name="$" />
            </div>
          </div>
        </div>
      )}

      {value?.map((item, itemIndex) =>
        Children.map(children, (child, childIndex) =>
          isValidElement(child)
            ? cloneElement(child, {
                key: `${itemIndex}-${childIndex}`,
                name: child.props.name?.replace('$', '' + itemIndex),
                ...itemProps,
              })
            : child,
        ),
      )}
    </ul>
  );
}

export default connectField<ListFieldProps>(List);
