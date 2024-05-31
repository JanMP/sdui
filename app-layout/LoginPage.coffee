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
        Sie sind als Benutzer eingeloggt, aber wir müssen Ihr Konto manuell für die entsprechenden Module freischalten.
        Bitte geben Sie uns Bescheid, unter welchem Account sie sich angemeldet haben. Wir kümmern uns umgehend.
      </p> unless isUser}
      <ActionButton
        onAction={Meteor.logout}
        label="Logout"
      />
    </div>

  <div className="w-full mt-4 flex justify-content-center" >
    <LoginForm />
  </div>