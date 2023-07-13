import React from 'react'
import {Meteor} from 'meteor/meteor'
import {useTracker} from 'meteor/react-meteor-data'
import {Gravatar} from '../forms/GravatarField'
import {MarkdownDisplay} from '../markdown/MarkdownDisplay'

export Message = ({message}) ->

  {_id, userId, text, username, email, chatRole, customImage} = message

  # isCurrentUser = useTracker -> Meteor.userId() is userId

  chatRoleClassName =
    switch chatRole
      when 'user' then 'p-card p-card-secondary'
      when 'assistant' then 'p-card p-card-secondary'
      else ''


  <div
    className={"p-3 mb-2 flex gap-4 #{chatRoleClassName}"}
  >
    <Gravatar email={email} customImage={customImage} shape="circle" size="xlarge"/>
    <div className="content-container">
      <div className="text font-bold">
        {username}:
      </div>
      <div>
        <MarkdownDisplay markdown={text} contentClass="chat-message"/>
      </div>
    </div>
  </div>