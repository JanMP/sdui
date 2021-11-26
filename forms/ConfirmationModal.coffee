import React, {useState} from 'react'
import Modal from 'react-modal'
import {useTw} from '../config.coffee'


export ConfirmationModal = ({text, onConfirm = ->, onCancel = ->, isOpen, setIsOpen}) ->

  tw = useTw()

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
    <div className={tw"mt-4 flex justify-end"}>
      <button className={tw"bg-secondary-400! text-white!"} onClick={handleCancelClick} >Abbrechen</button>
      <button className={tw"ml-2 bg-primary-400! text-white!"} onClick={handleOkClick} >OK</button>
    </div>
  </Modal>