import React from 'react'
import {Accounts} from 'meteor/accounts-base'
import SimpleSchema from 'meteor/aldeed:simple-schema'
import SimpleSchemaBridge from 'uniforms-bridge-simple-schema-2'
import {AutoForm, SubmitField, PasswordField} from '../forms/uniforms-custom/select-implementation'


# TODO [PrimeReact] switch to PrimeReact password input
passwordSchema = new SimpleSchema
  password:
    type: String
    label: 'Passwort'
    regEx: /^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])[0-9a-zA-Z]{8,}$/
    uniforms: PasswordField

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