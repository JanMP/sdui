import {Meteor} from 'meteor/meteor'
import {Accounts} from 'meteor/accounts-base'
import React, {useState} from 'react'
import {useTracker} from 'meteor/react-meteor-data'
import {Schema, useToast} from 'meteor/janmp:sdui'
import {AutoForm} from '../forms/uniforms-custom/select-implementation'
import {Button} from 'primereact/button'
import {PasswordField} from '../forms/uniforms-custom/select-implementation'


loginSchema = new Schema
  type: 'object'
  properties:
    email:
      type: 'string'
      uniforms:
        label: 'E-Mail'
    password:
      type: 'string',
      uniforms:
        label: 'Passwort'
        component: PasswordField
  required: ['email', 'password']

signupSchema = new Schema
  type: 'object'
  properties:
    email:
      type: 'string'
      format: "email"
      uniforms:
        label: 'E-Mail'
    username:
      type: 'string'
      minLength: 3
      maxLength: 80
      uniforms:
        label: 'Benutzername'
    password:
      type: 'string'
      maxLength: 80
      uniforms:
        component: PasswordField
        label: 'Passwort'
    passwordRepeat:
      type: 'string'
      uniforms:
        component: PasswordField
        label: 'Passwort wiederholen'
  required: ['email', 'username', 'password', 'passwordRepeat']
,
  modelValidator: (model) ->
    if model.passwordRepeat isnt model.password
      'Die Passwörter müssen übereinstimmen.'

emailSchema = new Schema
  type: 'object'
  properties:
    email:
      type: 'string'
      format: 'email'
      uniforms:
        label: 'E-Mail'
  required: ['email']


SignInForm = ->
  toast = useToast()
  login = ({email, password}) ->
    # console.log 'login', {email, password}
    Meteor.loginWithPassword email, password, (error) ->
      if error
        toast.show
          severity: 'error'
          summary: 'Fehler'
          detail: error.message
      else
        toast.show
          severity: 'success'
          summary: 'Erfolg'
          detail: 'Login erfolgreich'

  <AutoForm
    schema={loginSchema.bridge}
    submitField={-> <Button className="mt-4" label="Login" />}
    onSubmit={login}
  />


SignUpForm = ->
  toast = useToast()
  signup = (model) ->
    Accounts.createUser model, (error) ->
      if error
        toast.show
          severity: 'error'
          summary: 'Fehler'
          detail: error?.message
      else
        toast.show
          severity: 'success'
          summary: 'Erfolg'
          detail: 'Account erfolgreich angelegt'

  <AutoForm
    schema={signupSchema.bridge}
    submitField={-> <Button className="mt-4" label="Account anlegen" />}
    onSubmit={signup}
  />

EmailForm = ->
  toast = useToast()
  resetPassword = ({email}) ->
    Accounts.forgotPassword {email}, (error) ->
      if error
        toast.show
          severity: 'error'
          summary: 'Fehler'
          detail: 'Fehler beim Zurücksetzen des Passworts: ' + error?.message
      else
        toast.show
          severity: 'success'
          summary: 'Erfolg'
          detail: 'Passwort zurücksetzen E-Mail gesendet'

  <AutoForm
    schema={emailSchema.bridge}
    submitField={-> <Button className="mt-4" label="Password zurücksetzen" />}
    onSubmit={resetPassword}
  />

export LoginForm = ({allowResetPassword = false}) ->
  [formToShow, setFormToShow] = useState 'sign-in'
  user = useTracker -> Meteor.user()

  [Form, loginOrSignupLabel] = switch formToShow
    when 'sign-in' then [SignInForm, 'Ich habe noch keinen Account']
    when 'sign-up' then [SignUpForm, 'Ich habe bereits einen Account']
    when 'reset-password' then [EmailForm, 'Ich habe noch keinen Account']
    else [null, 'fnord']

  toggleLoginOrSignup = ->
    if formToShow is 'sign-up' then setFormToShow 'sign-in' else setFormToShow 'sign-up'


  <div className="p-component w-16rem">
    <Form />
    {<div className="text-center mt-4">
      <a onClick={-> setFormToShow 'reset-password'}>Ich habe mein Passwort vergessen</a>
    </div> if allowResetPassword and formToShow isnt 'reset-password'}
    {<div className="text-center mt-4">
      <a onClick={toggleLoginOrSignup}>{loginOrSignupLabel}</a>
    </div> if loginOrSignupLabel?}
  </div>