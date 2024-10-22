import React from 'react'
import {Meteor} from 'meteor/meteor'
import {useTracker} from 'meteor/react-meteor-data'
import {Button} from 'primereact/button'
import {Toolbar} from 'primereact/toolbar'
import {LoginButton} from 'meteor/janmp:sdui'
import {useNavigate} from 'react-router-dom'

export AppToolbar = ({toolbarStart, isMobile, onToggleSidebar}) ->
  navigate = useNavigate()

  end =
    if isMobile
      <div className="flex">
        <LoginButton
          onLoginClick={ -> navigate 'login' }
          onUserClick={ -> navigate 'login'}
        />
        <Button
          icon="pi pi-bars"
          severity="secondary"
          size="large"
          text
          onClick={onToggleSidebar}
        />
      </div>
    else
      <LoginButton
        onLoginClick={ -> navigate 'login' }
        onUserClick={ -> navigate 'login'}
      />
    
  <Toolbar start={toolbarStart} end={end}/>