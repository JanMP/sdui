import React from 'react'
import {Dialog} from 'primereact/dialog'

import {ManagedForm} from './ManagedForm.coffee'

export FormModal = ({schemaBridge, onSubmit, model,
isOpen, onRequestClose, header, children, disabled = false, readOnly,
submitField, onChangeModel}) ->

  # submitField = -> <button className="button primary">Ok</button>

  <Dialog
    visible={isOpen}
    onHide={onRequestClose}
    header={header}
    contentStyle={display: 'flex', flexDirection: 'column', justifyContent: 'space-between', padding: 0}
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
