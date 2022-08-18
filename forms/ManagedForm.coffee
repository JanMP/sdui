import React, {useRef, useState, useEffect} from 'react'
import {AutoForm} from './uniforms-custom/select-implementation'
import {useForm} from 'uniforms'
import {ActionButton} from './ActionButton.coffee'
import isEqual from 'lodash/isEqual'
import {ErrorBoundary} from '../common/ErrorBoundary.coffee'



export ManagedForm = ({schemaBridge, model, onChangeModel, onSubmit, disabled, children}) ->

  onChangeModel ?= ->

  form = null
  [changedModel, setChangedModel] = useState model
  [isValid, setIsValid] = useState false

  hasChanged = not isEqual changedModel, model

  onAction = -> onSubmit changedModel
  
  onValidate = (model, error) ->
    setIsValid not error?
    error
  
  handleChange = (newModel) ->
    setChangedModel newModel
    onChangeModel newModel

  <ErrorBoundary>
    <div className="m-1 p-2">
      <AutoForm
        ref={(ref) -> form = ref}
        schema={schemaBridge}
        model={model}
        onChangeModel={handleChange}
        onValidate={onValidate}
        submitField={-> null}
        validate="onChange"
        children={children}
        disabled={disabled}
      />
      <ActionButton
        onAction={-> form.reset()}
        className="danger"
        label="Zurücksetzen"
        disabled={not hasChanged}
      />
      <ActionButton
        onAction={onAction}
        className="primary"
        label="Speichern"
        disabled={(not hasChanged) or (not isValid)}
      />
    </div>
  </ErrorBoundary>