import React, {useState} from 'react'
import Modal from 'react-modal'

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
  >
    <div>{text}</div>
    <div className="button-row">
      <button className="cancel-button" onClick={handleCancelClick} >Abbrechen</button>
      <button className="ok-button" onClick={handleOkClick} >OK</button>
    </div>
  </Modal>