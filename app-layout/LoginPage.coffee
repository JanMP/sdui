import {Meteor} from 'meteor/meteor'
import React, {useEffect} from 'react'

import {LoginForm, ActionButton, useCurrentUserIsInRole}  from 'meteor/janmp:sdui'
import {useTracker} from 'meteor/react-meteor-data'

export LoginPage =  ->

  isLoggedIn = useCurrentUserIsInRole 'logged-in'
  isUser = useCurrentUserIsInRole role: 'user', forAnyScope: true
  
  user = useTracker -> Meteor.user()


  if isLoggedIn
    return <div className="prose p-4">
      <p>Hallo {user?.emails?[0]?.address ? ''}!</p>
      {<p>
        Sie sind als Benutzer eingeloggt. Falls sie auf bestimmte Funktionen nicht zugreifen können,
        müssen sie sich u.U. mit einem anderen Account anmelden, der über die entsprechenden Rechte verfügt.
      </p> unless isUser}
      <ActionButton
        onAction={Meteor.logout}
        label="Logout"
      />
    </div>

  <div className="w-full mt-4 flex justify-content-center" >
    <LoginForm />
  </div>