import React from 'react'

import AutoForm from './uniforms-custom/AutoForm'
import AutoField from './uniforms-custom/AutoField'

import Modal from 'react-modal'


export default FormModal = ({schemaBridge, onSubmit, model,
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
