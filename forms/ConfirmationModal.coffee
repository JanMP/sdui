import React, {useState} from 'react'
import Modal from 'react-modal'
import {useTw} from '../config.coffee'

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
    shouldFocusAfterRender={false}
  >
    <div>{text}</div>
    <div className={tw"mt-4 flex justify-end"}>
      <button className={tw"button secondary"} onClick={handleCancelClick} >Abbrechen</button>
      <button className={tw"ml-2 button primary"} onClick={handleOkClick} >OK</button>
    </div>
  </Modal>