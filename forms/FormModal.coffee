import React from 'react'
import {AutoForm} from './uniforms-custom/select-implementation'
import Modal from 'react-modal'
import {faXmark} from '@fortawesome/free-solid-svg-icons/faXmark'
import {ActionButton} from './ActionButton.coffee'

export FormModal = ({schemaBridge, onSubmit, model,
isOpen, onRequestClose, header, children, disabled = false, readOnly,
submitField, onChangeModel}) ->

  <Modal
    isOpen={isOpen}
    onRequestClose={onRequestClose}
    className="modal"
    overlayClassName="overlay"
    shouldFocusAfterRender={false}
  >
    <div className="button-container">
      <ActionButton onAction={onRequestClose} className="secondary icon" icon={faXmark}/>
    </div>
    {if header? then <h2> {header} </h2>}
    <AutoForm
      schema={schemaBridge}
      onSubmit={onSubmit}
      model={model}
      children={children}
      disabled={disabled}
      onChangeModel={onChangeModel}
      submitField={-> null}
    />
  </Modal>
