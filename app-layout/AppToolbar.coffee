import React from 'react'
import {Meteor} from 'meteor/meteor'
import {useTracker} from 'meteor/react-meteor-data'
import {Toolbar} from 'primereact/toolbar'
import {LoginButton} from 'meteor/janmp:sdui'
import {useNavigate} from 'react-router-dom'

export AppToolbar = ({toolbarStart}) ->
  navigate = useNavigate()

  loginButton =
    <LoginButton
      onLoginClick={ -> navigate 'login' }
      onUserClick={ -> navigate 'login'}
    />
    
  <Toolbar start={toolbarStart ? -> null} end={loginButton}/>