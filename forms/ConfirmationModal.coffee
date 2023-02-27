import React from 'react'
import {ConfirmDialog} from 'primereact/confirmdialog'
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

  <ConfirmDialog
    visible={isOpen}
    onHide={-> setIsOpen false}
    message={t text}
    accept={onConfirm}
    reject={onCancel}
  />