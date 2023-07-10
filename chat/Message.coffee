import React from 'react'
import {Meteor} from 'meteor/meteor'
import {useTracker} from 'meteor/react-meteor-data'
import Gravatar from 'react-gravatar'

export Message = ({message}) ->

  {_id, userId, text, username, email, chatRole} = message

  # isCurrentUser = useTracker -> Meteor.userId() is userId

  chatRoleClassName =
    switch chatRole
      when 'user' then 'p-card p-card-secondary'
      when 'bot' then 'p-card p-card-secondary'
      else ''


  <div
    key={_id}
    className={"p-3 flex gap-4 #{chatRoleClassName}"}
  >
    <Gravatar email={email} className="border-circle"/>
    <div className="content-container">
      <div className="text font-bold">
        {username}:
      </div>
      <div>
        {text}
      </div>
    </div>
  </div>