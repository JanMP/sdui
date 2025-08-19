import React from 'react'
import {SdWorkspace} from 'meteor/janmp:sdui'

export createWorkspacePage = ({workspaceApi}) -> ->
  <SdWorkspace api={workspaceApi} />
