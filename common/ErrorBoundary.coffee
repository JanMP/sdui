import {Meteor} from 'meteor/meteor'
import React, {Fragment} from 'react'

export class ErrorBoundary extends React.Component
  constructor: (props) ->
    super props
    @state =
      hasError: false
      msg: 'everything is shiny'

  componentDidCatch: (error, info) ->
    @setState
      hasError: true
      msg: error.message ? 'unexpectedError'
    console.log 'Caught by ErrorBoundary:', error

  resetEditor: ->
    Meteor.call 'ruleEditorWorkspace.openFresh', -> location.reload()

  render: ->
    if @state.hasError
      <div className="error-boundary">{@state.msg}</div>
    else
      @props.children
