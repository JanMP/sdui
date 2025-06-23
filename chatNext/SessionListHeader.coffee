import React from 'react'
import {ActionButton} from '../forms/ActionButton'

export SessionListHeader = ({onAdd}) ->

  <div className="py-3">
    <ActionButton
      icon="pi pi-plus"
      label="Neuer Chat"
      className="w-full"
      onAction={onAdd}
      buttonProps={
        outlined: true
        rounded: true
      }
    />
  </div>