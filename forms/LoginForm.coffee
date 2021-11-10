import {Meteor} from 'meteor/meteor'
import {Accounts} from 'meteor/accounts-base'
import React, {useState} from 'react'
import {useTracker} from 'meteor/react-meteor-data'
import SimpleSchema from 'simpl-schema'
import SimpleSchemaBridge from 'uniforms-bridge-simple-schema-2'
import AutoForm from './uniforms-custom/AutoForm.tsx'
import SubmitField from './uniforms-custom/SubmitField.tsx'


SimpleSchema.extendOptions(['uniforms'])

loginSchema = new SimpleSchema
  email:
    type: String,
    label: 'E-Mail'
  password:
    type: String,
    label: 'Passwort'
    uniforms:
      type: 'password'

signupSchema = new SimpleSchema
  email:
    type: String
    label: 'E-Mail'
    regEx: SimpleSchema.RegEx.EmailWithTLD
  username:
    type: String
    label: 'Benutzername'
    min: 3
    max: 80
  password:
    type: String
    label: 'Passwort'
    # TODO: change regEx to accomodate sick desire for untripleclickselectable password
    regEx: /^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])[0-9a-zA-Z]{8,}$/
    max: 80
    uniforms:
      type: 'password'
  passwordRepeat:
    type: String
    label: 'Password wdh.'
    custom: ->
      if @value isnt @field('password').value then 'password mismatch'
    uniforms:
      type: 'password'

emailSchema = new SimpleSchema
  email:
    type: String
    label: 'E-Mail'
    regEx: SimpleSchema.RegEx.EmailWithTLD

loginSchemaBridge = new SimpleSchemaBridge loginSchema
signupSchemaBridge = new SimpleSchemaBridge signupSchema
emailSchemaBridge = new SimpleSchemaBridge emailSchema


LoginForm = ->
  login = ({email, password}) ->
    console.log 'login', {email, password}
    Meteor.loginWithPassword email, password, (error) ->
      console.log 'login callback'
      if error
        alert 'Login fehlgeschlagen: ' + error
 
  <AutoForm
    schema={loginSchemaBridge}
    submitField={-> <SubmitField value="Login" />}
    onSubmit={login}
  />


SignupForm = ->
  signup = (model) ->
    console.log 'wtf'
    Accounts.createUser model, (error) ->
      if error
        alert 'User Account konnte nicht angelegt werden: ' + error?.message

  <AutoForm
    schema={signupSchemaBridge}
    submitField={-> <SubmitField value="Account anlegen" />}
    onSubmit={signup}
  />

EmailForm = ->
  resetPassword = ({email}) ->
    Accounts.forgotPassword {email}, (error) ->
      if error
        alert 'Fehler beim Zurücksetzen des Passowrds' + error?.message

  <AutoForm
    schema={emailSchemaBridge}
    submitField={-> <SubmitField value="Password zurücksetzen" />}
    onSubmit={resetPassword}
  />

export default ({allowResetPassword = false}) ->
  [formToShow, setFormToShow] = useState 'login'
  user = useTracker -> Meteor.user()

  [Form, loginOrSignupLabel] = switch formToShow
    when 'login' then [LoginForm, 'Ich habe noch keinen Account']
    when 'signup' then [SignupForm, 'Ich habe bereits einen Account']
    when 'resetPassword' then [EmailForm, 'Ich habe noch keinen Account']
    else [null, 'fnord']

  toggleLoginOrSignup = ->
    if formToShow is 'signup' then setFormToShow 'login' else setFormToShow 'signup'
  

  <div>
    <Form />
    { <div>
      <a onClick={-> setFormToShow 'resetPassword'}>Ich habe mein Passwort vergessen</a>
    </div> if allowResetPassword and formToShow isnt 'resetPassword'}
    {<div>
      <a onClick={toggleLoginOrSignup}>{loginOrSignupLabel}</a>
    </div> if loginOrSignupLabel?}
  </div>