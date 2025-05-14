import React from 'react'
import {Meteor} from 'meteor/meteor'
import {useTracker} from 'meteor/react-meteor-data'
import {Gravatar} from '../forms/GravatarField'
import {MarkdownDisplay} from '../markdown/MarkdownDisplay'
import {Button} from 'primereact/button'
import {Tag} from 'primereact/tag'
import {usePDF} from 'react-to-pdf'
import {FeedbackButton} from '../forms/FeedbackButtonField'
import _ from 'lodash'


export DefaultMessage = ({message, hasPdfButton = true, onChangeFeedback, showTools = true}) ->

  if message.error?
    return <div className="p-3 pr-6 mb-2 p-card p-card-secondary border-1 border-red-500 overflow-hidden whitespace-normal chat-message">
        <div className="font-bold text-xl text-red-500">{message.error.error}</div>
        <div className="text">{message.error.message}</div>
    </div>

  {_id, userId, text, tools, username, email, chatRole, customImage, feedback} = message


  # TODO: make configurable
  {toPDF, targetRef} = usePDF filename: "Gespeicherte_Chat_Nachricht.pdf"

  gravatarPt =
    root:
      className: 'flex-shrink-0'

  <div
    className={"relative p-3 pr-6 mb-2 flex gap-4 p-card p-card-secondary overflow-hidden whitespace-normal chat-message"}
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
      {
        if tools? and showTools
          <div className="">
          {
            tools.map (tool) ->
              <div className="p-card p-2 surface-200 flex align-items-center gap-4 mt-2 mb-2 p-card-secondary chat-tool" key={tool.name}>
                <i className="pi pi-cog ml-2" style={fontSize: "2rem"}></i>
                <div>
                  <div className="font-semibold">{tool.name}: </div>
                  <div className="max-h-6rem overflow-y-auto">
                    {
                      _.keys tool.args
                      .map (key) -> <div className="ml-2">{"#{key}: #{JSON.stringify tool.args[key]}"}</div>
                    }
                  </div>
              </div>
                </div>
          }
          </div>
      }
    </div>

  </div>