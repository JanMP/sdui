import {Meteor} from 'meteor/meteor'
import React from 'react'
import {Message} from 'primereact/message'

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
    console.error 'Caught by ErrorBoundary:', error

  resetEditor: ->
    Meteor.call 'ruleEditorWorkspace.openFresh', -> location.reload()

  render: ->
    if @state.hasError
      <Message text={@state.msg} />
    else
      @props.children
