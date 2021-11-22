import React, {useState, useEffect} from 'react'
import {meteorApply} from '../common/meteorApply.coffee'
import {toast} from 'react-toastify'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faSpinner} from '@fortawesome/free-solid-svg-icons/faSpinner'
import _ from 'lodash'


import {ConfirmationModal} from './ConfirmationModal'

export MeteorMethodButton = ({method, data, options, handler, label, icon, className,
onSuccess, successMsg, onError, errorMsg, disabled, confirmation}) ->

  data ?= {}
  options ?= {}
  label ?= unless icon? then "run #{method}"
  className ?= if icon? and not label? then 'icon-button'

  onSuccess ?= (result) -> if successMsg? then toast.success successMsg
  onError ?= (error) -> toast.error "#{errorMsg ? error}"

  [isBusy, setIsBusy] = useState false
  [modalIsOpen, setModalIsOpen] = useState false

  doIt = ->
    setModalIsOpen false
    setIsBusy true
    (
      if handler?
        new Promise (resolve) -> resolve handler()
      else
        meteorApply {method, data, options}
    )
    .then (result) ->
      onSuccess result
      setIsBusy false
    .catch (error) ->
      onError error
      setIsBusy false
  
  handleClick = (e) ->
    e.stopPropagation()
    if confirmation?
      setModalIsOpen true
    else
      doIt()


  <>
    {
      if confirmation?
        <ConfirmationModal
          text={confirmation}
          isOpen={modalIsOpen}
          setIsOpen={setModalIsOpen}
          onConfirm={doIt}
        />
    }
    <button
      className={className}
      disabled={disabled}
      onClick={handleClick}
    >
      {
        if icon?
          if isBusy
            <FontAwesomeIcon icon={faSpinner} fixedWidth spin/>
          else
            <FontAwesomeIcon icon={icon} fixedWidth />
      }{
        if label?
          <span> {label}</span>
      }
    </button>
  </>
