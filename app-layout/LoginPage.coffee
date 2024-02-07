import {Meteor} from 'meteor/meteor'
import React from 'react'

import {LoginForm, ActionButton, useCurrentUserIsInRole}  from 'meteor/janmp:sdui'
import {useTracker} from 'meteor/react-meteor-data'

export LoginPage =  ->

  isLoggedIn = useCurrentUserIsInRole 'logged-in'
  isUser = useCurrentUserIsInRole 'user'

  user = useTracker -> Meteor.user()

  if isLoggedIn
    return <div className="prose p-4">
      <p>Hallo {user?.emails?[0]?.address ? ''}!</p>
      {<p>
        You are logged in as a user, but we will have to manually approve your account, befor you can use it.
      </p> unless isUser}
      <ActionButton
        onAction={Meteor.logout}
        label="Logout"
      />
    </div>

  <div className="w-full mt-4 flex justify-content-center" >
    <LoginForm />
  </div>