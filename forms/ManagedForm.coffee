import React, {useRef, useState, useEffect} from 'react'
import {AutoForm} from './uniforms-custom/select-implementation'
import {ActionButton} from './ActionButton.coffee'
import isEqual from 'lodash/isEqual'
import {ErrorBoundary} from '../common/ErrorBoundary.coffee'
import {useTranslation} from 'react-i18next'


export ManagedForm = ({schemaBridge, model, onChangeModel, onSubmit,
disabled, children, actionLabel = 'Speichern', showResetButton = true,
allowUnchangedSubmit = false}) ->

  {t} = useTranslation()

  onChangeModel ?= ->

  form = useRef null

  [changedModel, setChangedModel] = useState model
  [isValid, setIsValid] = useState false

  hasChanged = not isEqual changedModel, model

  onAction = -> onSubmit changedModel

  onValidate = (model, error) ->
    # console.log 'onValidate', {model, error}
    setIsValid not error?
    error

  handleChange = (newModel) ->
    setChangedModel newModel
    onChangeModel newModel

  <ErrorBoundary>
    <div className="flex-auto overflow-hidden flex flex-column justify-content-between gap-2">
     <div className="flex-shrink-1 overflow-y-scroll p-2">
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
          showInlineError={true}
          errorsField={-> null}
        />
     </div>
      <div className="pt-4 flex justify-content-end gap-2">
        {
          if showResetButton
            <ActionButton
              onAction={-> form.reset()}
              className="p-button-warning"
              label={t 'sdui:reset', 'Zurücksetzen'}
              disabled={not hasChanged}
            />
        }
        <ActionButton
          onAction={onAction}
          className="p-button-primary"
          label={t 'sdui:save', actionLabel}
          disabled={(not (hasChanged or allowUnchangedSubmit)) or (not isValid)}
        />
      </div>
    </div>
  </ErrorBoundary>