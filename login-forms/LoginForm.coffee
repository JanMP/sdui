import {Meteor} from 'meteor/meteor'
import {Accounts} from 'meteor/accounts-base'
import React, {useState} from 'react'
import {useTracker} from 'meteor/react-meteor-data'
import SimpleSchema from 'meteor/aldeed:simple-schema'
import SimpleSchemaBridge from 'uniforms-bridge-simple-schema-2'
import {AutoForm} from '../forms/uniforms-custom/select-implementation'
import {Button} from 'primereact/button'
import {PasswordField} from '../forms/uniforms-custom/select-implementation'


SimpleSchema.extendOptions(['uniforms'])

loginSchema = new SimpleSchema
  email:
    type: String,
    label: 'E-Mail'
  password:
    type: String,
    label: 'Passwort'
    uniforms: PasswordField

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
    regEx: /^(?=.*\d)(?=.*[a-z])(?=.*[A-Z]).{8,}$/
    max: 80
    uniforms: PasswordField
  passwordRepeat:
    type: String
    label: 'Password wdh.'
    custom: ->
      if @value isnt @field('password').value then 'password mismatch'
    uniforms: PasswordField

emailSchema = new SimpleSchema
  email:
    type: String
    label: 'E-Mail'
    regEx: SimpleSchema.RegEx.EmailWithTLD

loginSchemaBridge = new SimpleSchemaBridge loginSchema
signupSchemaBridge = new SimpleSchemaBridge signupSchema
emailSchemaBridge = new SimpleSchemaBridge emailSchema


SignInForm = ->
  login = ({email, password}) ->
    # console.log 'login', {email, password}
    Meteor.loginWithPassword email, password, (error) ->
      if error
        alert 'Login fehlgeschlagen: ' + error
 
  <AutoForm
    schema={loginSchemaBridge}
    submitField={-> <Button label="Login" />}
    onSubmit={login}
  />


SignUpForm = ->
  signup = (model) ->
    Accounts.createUser model, (error) ->
      if error
        alert 'User Account konnte nicht angelegt werden: ' + error?.message

  <AutoForm
    schema={signupSchemaBridge}
    submitField={-> <Button label="Account anlegen" />}
    onSubmit={signup}
  />

EmailForm = ->
  resetPassword = ({email}) ->
    Accounts.forgotPassword {email}, (error) ->
      if error
        alert 'Fehler beim Zurücksetzen des Passowrds' + error?.message

  <AutoForm
    schema={emailSchemaBridge}
    submitField={-> <Button label="Password zurücksetzen" />}
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
    { <div className="text-center mt-4">
      <a onClick={-> setFormToShow 'resetPassword'}>Ich habe mein Passwort vergessen</a>
    </div> if allowResetPassword and formToShow isnt 'resetPassword'}
    {<div className="text-center mt-4">
      <a onClick={toggleLoginOrSignup}>{loginOrSignupLabel}</a>
    </div> if loginOrSignupLabel?}
  </div>