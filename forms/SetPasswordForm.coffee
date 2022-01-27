import React from 'react'
import {Accounts} from 'meteor/accounts-base'
import SimpleSchema from 'simpl-schema'
import SimpleSchemaBridge from 'uniforms-bridge-simple-schema-2'
import {AutoForm, SubmitField} from './uniforms-custom'

passwordSchema = new SimpleSchema
  password:
    type: String
    label: 'Passwort'
    # TODO: change regEx to accomodate sick desire for untripleclickselectable password
    regEx: /^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])[0-9a-zA-Z]{8,}$/
    uniforms:
      type: 'password'

passwordSchemaBridge = new SimpleSchemaBridge passwordSchema

export SetPasswordForm = ({token}) ->
  
  setPassword = ({password}) ->
    Accounts.resetPassword token, password, (error) ->
      if error
        alert 'Fehler beim Zurücksetzen des Passworts: ' + error?.message

  <AutoForm
    schema={passwordSchemaBridge}
    submitField={-> <SubmitField value="Passwort setzen" />}
    onSubmit={setPassword}
  />