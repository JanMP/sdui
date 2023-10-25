import React from 'react'
import {Meteor} from 'meteor/meteor'
import {useTracker} from 'meteor/react-meteor-data'
import {Gravatar} from '../forms/GravatarField'
import {MarkdownDisplay} from '../markdown/MarkdownDisplay'
import {Button} from 'primereact/button'
import {usePDF} from 'react-to-pdf'

export DefaultMessage = ({message}) ->

  {_id, userId, text, username, email, chatRole, customImage} = message

  {toPDF, targetRef} = usePDF filename: "Nachricht_von_Cooky.pdf"

  gravatarPt =
    root:
      className: 'flex-shrink-0'


  <div
    className={"relative p-3 pr-6 mb-2 flex gap-4 p-card p-card-secondary chat-message"}
    ref={targetRef}
  >
    <Button className="absolute top-0 right-0" icon="pi pi-file-pdf" rounded text onClick={toPDF}/>
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