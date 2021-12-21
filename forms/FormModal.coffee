import React from 'react'

import {AutoForm} from 'uniforms-custom'

import Modal from 'react-modal'


export FormModal = ({schemaBridge, onSubmit, model,
isOpen, onRequestClose, header, children, disabled = false, readOnly}) ->

  <Modal
    isOpen={isOpen}
    onRequestClose={onRequestClose}
    className="modal"
    overlayClassName="overlay"
  >
    {if header? then <h2> {header} </h2>}
    
    <AutoForm
      schema={schemaBridge}
      onSubmit={onSubmit}
      model={model}
      children={children}
      disabled={disabled}
      validate="onChange"
    />
  </Modal>
