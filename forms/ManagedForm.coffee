import React, {useRef, useState, useEffect} from 'react'
import {AutoForm} from './uniforms-custom/select-implementation'
import {useForm} from 'uniforms'
import {ActionButton} from './ActionButton.coffee'
import isEqual from 'lodash/isEqual'
import {ErrorBoundary} from '../common/ErrorBoundary.coffee'
import {useTranslation} from 'react-i18next'


export ManagedForm = ({schemaBridge, model, onChangeModel, onSubmit, disabled, children}) ->

  {t} = useTranslation()

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
    <div className="managed-form">
     <div className="form-container">
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
     </div>
      <div className="button-container">
        <ActionButton
          onAction={-> form.reset()}
          className="p-button-warning"
          label={t 'Reset'}
          disabled={not hasChanged}
        />
        <ActionButton
          onAction={onAction}
          className="p-button-primary"
          label={t 'Save'}
          disabled={(not hasChanged) or (not isValid)}
        />
      </div>
    </div>
  </ErrorBoundary>