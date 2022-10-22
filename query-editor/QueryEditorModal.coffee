import React, {useState} from 'react'
import Modal from 'react-modal'
import {QueryEditor} from './QueryEditor.coffee'
import {ActionButton} from '../forms/ActionButton.coffee'
import {faXmark} from '@fortawesome/free-solid-svg-icons/faXmark'

###*
  @param {Object} args
  @param {object} args.bridge
  @param {object} args.rule
  @param {(newValue: object) => void} args.onChangeRule
  @param {boolean} args.useQuery
  @param {(newValue: boolean) => void} args.setUseQuery
  @param {boolean} args.isOpen
  @param {(newValue : boolean) => void} args.setIsOpen
  @return void
  ###
export QueryEditorModal = ({bridge, rule, onChangeRule, isOpen, setIsOpen}) ->


  <Modal
    isOpen={isOpen}
    onRequestClose={-> setIsOpen false}
    className="modal query-editor-modal"
    overlayClassName="overlay"
    shouldFocusAfterRender={false}
  >
    <div className="button-container">
      <ActionButton
        className="secondary icon"
        onAction={-> setIsOpen false}
        icon={faXmark}
      />
    </div>
    <QueryEditor
      bridge={bridge}
      rule={rule}
      onChange={onChangeRule}
    />
  </Modal>