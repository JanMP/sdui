import React, {useEffect, useState} from 'react'
import {useSubscribe, useTracker} from 'meteor/react-meteor-data'
import {ManagedForm} from 'meteor/janmp:sdui'

export SdWorkspace = ({handler, documentId}) ->

  isLoading = useSubscribe handler.api.publicationName, id: handler.id

  document = useTracker -> (handler.api.collection.find sourceId: documentId)?[0]


  useEffect ->
    console.log 'SdWorkspace', documentId
    switch
      when documentId is 'new'
        handler.newDocument()
      else
        handler.loadDocument documentId
    undefined
  , [documentId]


  <div className="p-component p-card w-full h-full flex flex-column p-4">
    <ManagedForm
      schemaBridge={handler.api.dataSchema.bridge}
      model={document?.data}
      onSubmit={handler.setDocument}
    />
  </div>