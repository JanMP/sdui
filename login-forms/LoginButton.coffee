import React from 'react'
import {Meteor} from 'meteor/meteor'
import {useTracker} from 'meteor/react-meteor-data'
import {ActionButton} from '../forms/ActionButton'
import {Gravatar} from '../forms/GravatarField'

export LoginButton = ({onLoginClick, onUserClick}) ->

  user = useTracker -> Meteor.user()

  unless user
    return <ActionButton
        label="Login"
        icon="pi pi-fw pi-sign-in"
        onAction={onLoginClick}
      />

  email = user?.emails[0].address
  username = user?.username ? 'X'

  customTemplate =
      <Gravatar email={email} shape="circle"/>

  <ActionButton
    customTemplate={customTemplate}
    label={username}
    onAction={onUserClick}
    buttonProps={text:true}
  />