import React from 'react'
import {Dialog} from 'primereact/dialog'
import {className} from 'primereact/utils'

import {ManagedForm} from './ManagedForm.coffee'

export FormModal = ({schemaBridge, onSubmit, model,
isOpen, onRequestClose, header, children, disabled = false, readOnly, onChangeModel}) ->


  <Dialog
    visible={isOpen}
    onHide={onRequestClose}
    header={header}
    contentClassName="flex flex-column"
    style={minWidth: '50vw'}
    maximizable
  >
    <ManagedForm
      schemaBridge={schemaBridge}
      onSubmit={onSubmit}
      model={model}
      children={children}
      disabled={disabled}
      onChangeModel={onChangeModel}
    />
  </Dialog>
