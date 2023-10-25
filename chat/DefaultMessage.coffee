import React from 'react'
import {Meteor} from 'meteor/meteor'
import {useTracker} from 'meteor/react-meteor-data'
import {Gravatar} from '../forms/GravatarField'
import {MarkdownDisplay} from '../markdown/MarkdownDisplay'

export DefaultMessage = ({message}) ->

  {_id, userId, text, username, email, chatRole, customImage} = message

  gravatarPt =
    root:
      className: 'flex-shrink-0'


  <div
    className={"p-3 mb-2 flex gap-4 p-card p-card-secondary chat-message"}
  >
    <Gravatar email={email} customImage={customImage} shape="circle" size="xlarge" pt={gravatarPt}/>
    <div className="content-container">
      <div className="text font-bold">
        {username}:
      </div>
      <div>
        <MarkdownDisplay markdown={text} contentClass="chat-message"/>
      </div>
    </div>
  </div>