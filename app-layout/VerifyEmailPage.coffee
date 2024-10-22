import {Accounts} from 'meteor/accounts-base'
import React, {useState, useEffect} from 'react'
import {useParams} from 'react-router-dom'


export VerifyEmailPage = ->

  [errorMessage, setErrorMessage] = useState null
  [verified, setVerified] = useState false

  {token} = useParams()

  useEffect ->
    if token?
      Accounts.verifyEmail token, (error) ->
        if error?
          setErrorMessage error.message
        else
          setVerified true
  , [token]

  content = switch
    when errorMessage?
      <>
        <h1>Bei der Überprüfung ihrer Email ist ein Felhler aufgetreten:</h1>
        <div className="mt-2 text-xl text-danger-600">{errorMessage}</div>
      </>
    when verified
      <>
        <h1>Ihre Email Adresse wurde Verifiziert</h1>
      </>
    else
      <h1>Ihre Email Adresse wird Überprüft</h1>

  <div className="p-8">
    {content}
  </div>