import React from 'react'
import {ActionButton} from '../forms/ActionButton'
import {Toolbar} from 'primereact/toolbar'

export SessionListHeader = ({onAdd}) ->

  endContent =
    <ActionButton
      label="Neue Session"
      icon="pi pi-plus"
      onAction={onAdd}
      buttonProps={
        outlined: true
      }
    />

  <Toolbar end={endContent} />