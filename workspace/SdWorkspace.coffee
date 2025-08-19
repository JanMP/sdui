import React, {useEffect} from 'react'
import {ManagedForm} from 'meteor/janmp:sdui'

export SdWorkspace = ({api}) ->
  useEffect ->
    console.log api
    undefined
  , [api]

  <div className="p-component p-card w-full p-4">
    <ManagedForm
      schemaBridge={api.articleGenerationSchema.bridge}
      model={{}}
      onChangeModel={->}
    />
  </div>