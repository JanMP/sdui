import React from 'react'
import Modal from 'react-modal'
import {useTranslation} from 'react-i18next'

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

  {t} = useTranslation()

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
    <div className="text-container">{text}</div>
    <div className="button-container">
      <button className="button secondary" onClick={handleCancelClick} >{t 'Cancel'}</button>
      <button className="button primary" onClick={handleOkClick} >{t 'OK'}</button>
    </div>
  </Modal>