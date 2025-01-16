import React, {useState} from 'react'
import {useParams} from 'react-router-dom'
import {AutoForm, SubmitField, useToast, Schema} from 'meteor/janmp:sdui'
import {Accounts} from 'meteor/accounts-base'
import {Button} from 'primereact/button'

schema = new Schema
  type: 'object'
  properties:
    password:
      type: 'string'
      # regEx: /^(?=.*\d)(?=.*[a-z])(?=.*[A-Z]).{8,}$/
      maxLength: 80
      uniforms:
        label: 'Neues Passwort'
        type: 'password'
  required: ['password']

schemaBridge = schema.bridge


export ResetPasswordPage = ->

  {token} = useParams()
  [showSuccess, setShowSuccess] = useState false
  toast = useToast()

  resetPassword = ({password}) ->
    console.log 'resetPassword', password, token
    Accounts.resetPassword token, password, (error) ->
      console.log 'resetPassword', error
      if error?
        toast.show
          severity: 'error'
          summary: "Fehler beim Zurücksetzen des Passworts"
          detail: error.message
      else
        setShowSuccess true

  if showSuccess
    <div className="h-full w-10 p-8">
      <h1>Passwort wurde geändert.</h1>
      <p>Sie können sich nun mit dem neuen Passwort in der App anmelden.</p>
    </div>
  else
    <div className="h-full w-10 p-8">
      <AutoForm
        placeholder={true}
        schema={schemaBridge}
        submitField={-> <Button className="mt-4" label="Password ändern" />}
        onSubmit={resetPassword}
      />
    </div>