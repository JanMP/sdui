import React from 'react'
import {Meteor} from 'meteor/meteor'
import {useTracker} from 'meteor/react-meteor-data'
import Gravatar from 'react-gravatar'

export Message = ({message}) ->

  {_id, userId, text, username, email, chatRole} = message

  isCurrentUser = useTracker -> Meteor.userId() is userId

  className = "message #{chatRole} #{if isCurrentUser then 'current-user' else ''}"

  <div
    key={_id}
    className={className}
  >
    <div className="gravatar-container">
      <Gravatar email={email} size={24}/>
    </div>
    <div className="content-container">
      <div>
        {username}:
      </div>
      <div>
        {text}
      </div>
    </div>
  </div>