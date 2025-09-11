import React, {useEffect, useState} from 'react'
import {SdWorkspace, WorkspaceInstance} from 'meteor/janmp:sdui'

export createWorkspacePage =
  ({workspaceApi}) ->
    handler = new WorkspaceInstance api: workspaceApi
    ->

      <SdWorkspace handler={handler} />
