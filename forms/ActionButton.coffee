import React, {useState, useEffect} from 'react'

import {meteorApply} from '../common/meteorApply.coffee'
import {toast} from 'react-toastify'
import {ProgressSpinner} from 'primereact/progressspinner'
import {ConfirmationModal} from './ConfirmationModal'
import {Button} from 'primereact/button'
import _ from 'lodash'


###*
  @param {Object} args
  @param {string?} args.method - name of meteor method to be executed. either mothod or onAction should be defined
  @param {Object?} args.data - method arguments
  @param {Object?} args.options - method options
  @param {() => void} [args.onAction] - optional callback. either mothod or onAction should be defined
  @param {string?} args.label - optional button label
  @param {string?} args.icon - optional PrimeIcon (placed before label if label is defined)
  @param {(result: any) => void} [args.onSuccess] - optional callback on successfull method/action, defaults to toast.sucess(successMsg) if successMsg is defined
  @param {string?} args.successMsg - optional sucess message text
  @param {(error: Error) => void} [args.onError] - optional callback on unsuccessfull method/action, defaults to toast.error(errorMsg ? error)
  @param {string?} args.errorMsg - optional error message
  @param {string?} args.confirmation - if defined, a modal will be displayed with this text to request confirmation before method/action is executed
  @param {string?} args.className - applied to <button />
  @param {boolean?} args.disabled
  @param {Object?} args.buttonProps - props passed to Primereact <Button />
 ###
export ActionButton = ({method, data, options, onAction, label, icon,
onSuccess, successMsg, onError, errorMsg, confirmation, className, disabled,
buttonProps}) ->

  data ?= {}
  options ?= {}
  label ?= unless icon? then "run #{method}"

  onSuccess ?= (result) -> if successMsg? then toast.success successMsg
  onError ?= (error) -> toast.error "#{errorMsg ? error}"

  [isBusy, setIsBusy] = useState false
  [modalIsOpen, setModalIsOpen] = useState false

  doIt = ->
    setModalIsOpen false
    setIsBusy true
    (
      if onAction?
        new Promise (resolve) -> resolve onAction()
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
    <Button
      className={className}
      disabled={disabled}
      onClick={handleClick}
      {buttonProps...}
    >
      <div style={position: "relative"}>
        <div style={if isBusy then {visibility: "hidden"}}>
          {<i className={icon}/> if icon?}
          {<span> {label}</span> if label?}
        </div>
        {
          if isBusy
            <div
              style={
                position: "absolute"
                top: "0px", right: "0px", bottom: "0px", left: "0px"
                display: "grid"
                placeItems: "center"
              }
            >
              <i className="pi pi-spin pi-spinner"/>
            </div>
        }
      </div>
    </Button>
  </>
