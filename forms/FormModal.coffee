import React from 'react'
# import {AutoForm} from './uniforms-custom/select-implementation'
import Modal from 'react-modal'
import {faXmark} from '@fortawesome/free-solid-svg-icons/faXmark'
import {ActionButton} from './ActionButton.coffee'
import {ManagedForm} from './ManagedForm.coffee'

export FormModal = ({schemaBridge, onSubmit, model,
isOpen, onRequestClose, header, children, disabled = false, readOnly,
submitField, onChangeModel}) ->

  # submitField = -> <button className="button primary">Ok</button>

  <Modal
    isOpen={isOpen}
    onRequestClose={onRequestClose}
    className="modal form-modal"
    overlayClassName="overlay"
    shouldFocusAfterRender={false}
  >
    <div className="button-container">
      <ActionButton onAction={onRequestClose} className="secondary icon" icon={faXmark}/>
    </div>
    {if header? then <h2> {header} </h2>}
    <ManagedForm
      schemaBridge={schemaBridge}
      onSubmit={onSubmit}
      model={model}
      children={children}
      disabled={disabled}
      onChangeModel={onChangeModel}
    />
  </Modal>
