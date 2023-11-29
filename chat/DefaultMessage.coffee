import React from 'react'
import {Meteor} from 'meteor/meteor'
import {useTracker} from 'meteor/react-meteor-data'
import {Gravatar} from '../forms/GravatarField'
import {MarkdownDisplay} from '../markdown/MarkdownDisplay'
import {Button} from 'primereact/button'
import {usePDF} from 'react-to-pdf'
import {FeedbackButton} from '../forms/FeedbackButtonField'

export DefaultMessage = ({message, hasPdfButton = true, onChangeFeedback}) ->

  {_id, userId, text, username, email, chatRole, customImage, feedback} = message


  # TODO: make configurable
  {toPDF, targetRef} = usePDF filename: "Nachricht_von_CooKi.pdf"

  gravatarPt =
    root:
      className: 'flex-shrink-0'

  <div
    className={"relative p-3 pr-6 mb-2 flex gap-4 p-card p-card-secondary chat-message"}
    ref={targetRef}
  >
    <div className ="absolute top-0 right-0 flex">
      {<Button icon="pi pi-file-pdf" rounded text onClick={toPDF}/> if hasPdfButton}
      {<FeedbackButton value={message.feedback} onChange={onChangeFeedback}/> if onChangeFeedback?}
    </div>
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