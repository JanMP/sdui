import React from 'react'
import {Accounts} from 'meteor/accounts-base'
import {Schema} from '../schema/Schema.coffee'
import {AutoForm, SubmitField, PasswordField} from '../forms/uniforms-custom/select-implementation'

# NOTE: Password reset is handled by ResetPasswordPage.coffee with equivalent validation
# TODO: test this form, to check if the switch to Schema

passwordSchema = new Schema
  type: 'object'
  properties:
    password:
      title: 'Passwort'
      type: 'string'
      pattern: '^(?=.*\\d)(?=.*[a-z])(?=.*[A-Z])[0-9a-zA-Z]{8,}$'
      uniforms: PasswordField


export SetPasswordForm = ({token}) ->

  setPassword = ({password}) ->
    Accounts.resetPassword token, password, (error) ->
      if error
        alert 'Fehler beim Zurücksetzen des Passworts: ' + error?.message

  <AutoForm
    schema={passwordSchema.bridge}
    submitField={-> <SubmitField value="Passwort setzen" />}
    onSubmit={setPassword}
  />