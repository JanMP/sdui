import {Meteor} from 'meteor/meteor'
import React, {useEffect, useMemo, useState, useRef} from 'react'
import {useTracker} from 'meteor/react-meteor-data'
import {ActionButton, FormattedJSON, useToast} from 'meteor/janmp:sdui'
import {AutoForm} from '../forms/uniforms-custom/select-implementation'
import {TabView, TabPanel} from 'primereact/tabview'
import {ProgressSpinner} from 'primereact/progressspinner'
import {ConfirmDialog} from 'primereact/confirmdialog'
import {useTranslation} from 'react-i18next'
import isEqual from 'lodash/isEqual'
import _ from 'lodash'

###*
  SdWorkspace component with form locking and save functionality
  
  @param {Object} workspaceAPI - The workspace API instance
  @param {String} sessionId - Current chat session ID
  @param {String} documentId - Current document ID
  @param {Function} onReset - Reset callback
  @param {Component} CustomDisplay - Custom display component
  @param {Boolean} isLocked - Whether the form is locked (disabled)
  @param {String} lockReason - Human-readable reason for locking
  @param {Function} onLock - Called when form needs to be locked (should return Promise)
  @param {Function} onUnlock - Called when form needs to be unlocked
  @param {Function} onSaveWorkspace - Called to notify when data is saved to workspace
  @param {Function} onSaveToSource - Called to save workspace to source collection
  @param {Number} saveWorkspaceTrigger - Increment this value to trigger a workspace save
###
export SdWorkspace = ({
  workspaceAPI, sessionId, documentId, onReset, CustomDisplay,
  isLocked = false, lockReason = 'Agent is processing...',
  onLock, onUnlock, onSaveWorkspace, onSaveToSource, saveWorkspaceTrigger = 0
}) ->

  {t} = useTranslation()
  toast = useToast()
  form = useRef null
  
  # Form state management (similar to what ManagedForm provided)
  [changedModel, setChangedModel] = useState {}
  [isValid, setIsValid] = useState true
  [isSaving, setIsSaving] = useState false
  [showConfirmOverwrite, setShowConfirmOverwrite] = useState false

  subscribedModel = useTracker ->
    if workspaceAPI? and sessionId?
      handle = Meteor.subscribe workspaceAPI.publicationName, {sessionId}
      if handle.ready()
        (workspaceAPI.collection.findOne {sessionId})?.data

  # Initialize changedModel when subscribedModel changes (but only when not actively editing)
  useEffect ->
    if subscribedModel?
      setChangedModel subscribedModel
    undefined
  , [subscribedModel]

  useEffect ->
    if workspaceAPI? and sessionId? and documentId?
      workspaceAPI.setupWorkspaceMethod.call {sessionId, documentId}
    undefined
  , [workspaceAPI, sessionId, documentId]

  # Save to workspace when component unmounts if there are unsaved changes
  useEffect ->
    -> # cleanup function
      if hasChanged
        console.log 'Component unmounting, saving changes to workspace'
        saveCurrentDataToWorkspace()
    undefined
  , []

  # Respond to external save trigger
  useEffect ->
    if saveWorkspaceTrigger > 0
      saveCurrentDataToWorkspace()
    undefined
  , [saveWorkspaceTrigger]

  hasChanged = not isEqual changedModel, (subscribedModel ? {})

  # Form validation handler
  onValidate = (model, error) ->
    setIsValid not error?
    error

  # Form change handler - only update local state, don't save to workspace on every keystroke
  handleFormChange = (newModel) ->
    setChangedModel newModel

  # Save current form data to workspace (called strategically, not on every keystroke)
  saveCurrentDataToWorkspace = ->
    if hasChanged and workspaceAPI? and sessionId?
      try
        await workspaceAPI.setDocumentMethod.call {sessionId, data: changedModel}
        console.log 'Form data saved to workspace'
        # Notify parent component that save happened
        onSaveWorkspace?(changedModel)
      catch error
        console.error 'Error saving to workspace:', error
        toast.show
          severity: 'error'
          summary: 'Error'
          detail: "Failed to save to workspace: #{error.message}"

  # Manual unlock handler
  handleManualUnlock = ->
    try
      onUnlock?()
      toast.show
        severity: 'info'
        summary: 'Unlocked'
        detail: 'Form has been manually unlocked'
    catch error
      console.error 'Error unlocking form:', error
      toast.show
        severity: 'error'
        summary: 'Error'
        detail: error.message

  # Save to source collection handlers
  handleSaveToSource = (overwrite) ->
    return if isSaving or not isValid
    
    if overwrite and documentId?
      setShowConfirmOverwrite true
      return
    
    doSaveToSource overwrite

  doSaveToSource = (overwrite) ->
    setIsSaving true
    try
      # Validate form before saving to source
      unless isValid
        toast.show
          severity: 'warn'
          summary: 'Validation Error'
          detail: 'Please fix form validation errors before saving'
        return
      
      # Save to workspace first, then to source
      await saveCurrentDataToWorkspace()
      await onSaveToSource?(overwrite)
      toast.show
        severity: 'success'
        summary: 'Saved'
        detail: if overwrite then 'Document updated successfully' else 'New document created successfully'
    catch error
      console.error 'Error saving to source:', error
      toast.show
        severity: 'error'
        summary: 'Fehler'
        detail: error.message or 'An unexpected error occurred while saving'
    finally
      setIsSaving false
      setShowConfirmOverwrite false

  <div className="w-full h-full flex flex-column">
    {
      if false
        <div className="p-3">
          <ActionButton
            onAction={onReset}
            label="Reset Workspace"
            icon="pi pi-refresh"
            className="p-button-outlined"
            disabled={isLocked}
          />
        </div>
    }
    <div className="h-full relative">
      {
        if isLocked
          <div className={
            "absolute top-0 left-0 right-0 bottom-0 bg-black-alpha-10 z-5 " +
            "flex align-items-center justify-content-center"
          }>
            <div className="bg-white p-4 border-round shadow-3 text-center">
              <ProgressSpinner style={{width: '50px', height: '50px'}} strokeWidth="3" />
              <div className="mt-3 mb-3 text-lg">{lockReason}</div>
              <ActionButton
                onAction={handleManualUnlock}
                label="Manual Unlock"
                icon="pi pi-unlock"
                className="p-button-danger p-button-sm"
              />
            </div>
          </div>
      }

      <div style={{height: '100%', display: 'flex', flexDirection: 'column'}}>
        <style dangerouslySetInnerHTML={{
          __html: [
            '.p-tabview.h-full {',
            '  height: 100% !important;',
            '  display: flex !important;',
            '  flex-direction: column !important;',
            '}',
            '.p-tabview.h-full .p-tabview-panels {',
            '  flex: 1 !important;',
            '  min-height: 0 !important;',
            '  display: flex !important;',
            '  flex-direction: column !important;',
            '}',
            '.p-tabview.h-full .p-tabview-panel {',
            '  flex: 1 !important;',
            '  min-height: 0 !important;',
            '  display: flex !important;',
            '  flex-direction: column !important;',
            '}'
          ].join('\n')
        }} />
        <TabView className="h-full">
        <TabPanel header="Form">
          <div
            className="flex flex-column h-full"
            style={{minHeight: 0}}
          >
            <div className="flex-grow-1 overflow-auto p-2 min-h-0" style={{flex: 1, overflowY: 'auto', minHeight: 0}}>
              <AutoForm
                ref={(ref) -> form = ref }
                schema={workspaceAPI?.dataSchema?.bridge}
                model={changedModel}
                onChangeModel={handleFormChange}
                onValidate={onValidate}
                onSubmit={->}
                submitField={ -> null }
                validate="onChange"
                disabled={isLocked}
                showInlineError={true}
                errorsField={ -> null }
              />
            </div>
            <div className="flex-shrink-0 p-3 border-top-1 surface-border bg-surface-0">
              <div className="flex flex-wrap justify-content-between align-items-stretch gap-2">
                <div className="flex flex-wrap gap-2">
                  <ActionButton
                    onAction={ -> form?.reset?() }
                    label={t 'sdui:reset', 'Reset Form'}
                    icon="pi pi-undo"
                    className="p-button-warning flex-grow-1"
                    style={{minHeight: '2.5rem', minWidth: '8rem'}}
                    disabled={isLocked or not hasChanged}
                  />
                  {
                    if isLocked
                      <ActionButton
                        onAction={handleManualUnlock}
                        label="Unlock"
                        icon="pi pi-unlock"
                        className="p-button-danger p-button-outlined flex-grow-1"
                        style={{minHeight: '2.5rem', minWidth: '6rem'}}
                      />
                  }
                </div>
                <div className="flex flex-wrap gap-2">
                  <ActionButton
                    onAction={ -> handleSaveToSource true }
                    label="Save (Overwrite)"
                    icon="pi pi-save"
                    className="p-button-primary"
                    style={{minHeight: '2.5rem', minWidth: '9rem'}}
                    disabled={isLocked or isSaving or not isValid}
                    loading={isSaving}
                  />
                  <ActionButton
                    onAction={ -> handleSaveToSource false }
                    label="Save as New"
                    icon="pi pi-plus"
                    className="p-button-success"
                    style={{minHeight: '2.5rem', minWidth: '8rem'}}
                    disabled={isLocked or isSaving or not isValid}
                    loading={isSaving}
                  />
                </div>
              </div>
            </div>
          </div>
        </TabPanel>
        <TabPanel header="Raw">
          <FormattedJSON data={changedModel ? {}} />
        </TabPanel>

        {
          if CustomDisplay?
            <TabPanel header="Custom">
              <CustomDisplay
                data={changedModel ? {}}
              />
            </TabPanel>
        }

        </TabView>
      </div>
    </div>
    
    <ConfirmDialog
      visible={showConfirmOverwrite}
      onHide={ -> setShowConfirmOverwrite false }
      message="Are you sure you want to overwrite the existing document? This action cannot be undone."
      header="Confirm Overwrite"
      icon="pi pi-exclamation-triangle"
      accept={ -> doSaveToSource true }
      reject={ -> setShowConfirmOverwrite false }
    />
  </div>
