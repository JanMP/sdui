import React from 'react'
import {ActionButton} from '../forms/ActionButton'
import {Toolbar} from 'primereact/toolbar'

export SessionListHeader = ({onAdd}) ->

  endContent =
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

  <Toolbar center={endContent} />