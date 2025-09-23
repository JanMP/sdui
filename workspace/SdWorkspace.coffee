import {Meteor} from 'meteor/meteor'
import React, {useEffect, useMemo, useState} from 'react'
import {useTracker} from 'meteor/react-meteor-data'
import {ActionButton, ManagedForm, FormattedJSON} from 'meteor/janmp:sdui'
import {TabView, TabPanel} from 'primereact/tabview'
import _ from 'lodash'

export SdWorkspace = ({workspaceAPI, sessionId, documentId, onReset, CustomDisplay}) ->

  subscribedModel = useTracker ->
    if workspaceAPI? and sessionId?
      handle = Meteor.subscribe workspaceAPI.publicationName, {sessionId}
      if handle.ready()
        (workspaceAPI.collection.findOne {sessionId})?.data

  useEffect ->
    if workspaceAPI? and sessionId? and documentId?
      workspaceAPI.setupWorkspaceMethod.call {sessionId, documentId}
    undefined
  , [workspaceAPI, sessionId, documentId]

  saveModelToWorkspace = (data) ->
    if workspaceAPI? and sessionId?
      workspaceAPI.setDocumentMethod.call {sessionId, data}

  onSubmit = (data) ->
    if workspaceAPI? and sessionId?
      workspaceAPI.collection.update {sessionId},
        $set:
          data: data
          updatedAt: new Date()
      workspaceAPI.saveDocumentMethod.call {sessionId}

  <div className="w-full h-full flex flex-column">
    <div className="p-3">
      <ActionButton
        onAction={onReset}
        label="Reset Workspace"
        icon="pi pi-refresh"
        className="p-button-outlined"
      />
    </div>
    <div className="h-full">

      <TabView>
        <TabPanel header="Form">
          <ManagedForm
            schemaBridge={workspaceAPI.dataSchema.bridge}
            model={subscribedModel ? {}}
            onSubmit={saveModelToWorkspace}
          />
        </TabPanel>
        <TabPanel header="Raw">
          <FormattedJSON data={subscribedModel ? {}} />
        </TabPanel>

        {
          if CustomDisplay?
            <TabPanel header="Custom">
              <CustomDisplay
                data={subscribedModel ? {}}
              />
            </TabPanel>
        }

      </TabView>

    </div>
  </div>