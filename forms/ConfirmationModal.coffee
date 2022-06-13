import React, {useState} from 'react'
import Modal from 'react-modal'

###*
  @param {Object} args
  @param {string} args.text
  @param {() => void} [args.onConfirm]
  @param {() => void} [args.onCancel]
  @param {boolean} args.isOpen
  @param {(newValue : boolean) => void} args.setIsOpen
  @return void
  ###
export ConfirmationModal = ({text, onConfirm = ->, onCancel = ->, isOpen, setIsOpen}) ->

  handleOkClick = ->
    setIsOpen false
    onConfirm()

  handleCancelClick = ->
    setIsOpen false
    onCancel()

  <Modal
    isOpen={isOpen}
    onRequestClose={-> setIsOpen false}
    className="modal confirmation-modal"
    overlayClassName="overlay"
    shouldFocusAfterRender={false}
  >
    <div>{text}</div>
    <div className="mt-4 flex justify-end">
      <button className="button secondary" onClick={handleCancelClick} >Abbrechen</button>
      <button className="ml-2 button primary" onClick={handleOkClick} >OK</button>
    </div>
  </Modal>