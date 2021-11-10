import {Meteor} from 'meteor/meteor'
import React, {Fragment} from 'react'

export default class ErrorBoundary extends React.Component
  constructor: (props) ->
    super props
    @state = hasError: false

  componentDidCatch: (error, info) ->
    @setState hasError: true
    # console.log 'Caught by ErrorBoundary:', error

  resetEditor: ->
    Meteor.call 'ruleEditorWorkspace.openFresh', -> location.reload()

  render: ->
    if @state.hasError
      <div className="bg-red-200">error</div>
    else
      @props.children
