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
    {
      if chatRole is 'log' and (fc = message?.functionCall)?
        functionDescription = switch fc.name
          when 'get_recipes' then 'Suche in der Rezepte Datenbank'
          when 'get_recipe' then 'Rufe ein Rezept aus der Datenbank auf'
          when 'get_articles' then 'Suche in der Artikel Datenbank'
          when 'get_article' then 'Rufe einen Artikel aus der Datenbank auf'
          when 'answer_question' then 'Suche in der Wissensdatenbank'
          else fc.name
        <>
          <div>
            <div className="font-bold">{functionDescription}</div>
            <div className="p-2 text-600  font-light text-xl"> {fc.arguments?.description}</div>
            {
              _(fc.arguments)
              .keys()
              .map (key) ->
                if key.startsWith 'checkRequirement'
                  <Tag className="mr-2" value={key.replace 'checkRequirement', ''}/>
              .compact()
              .value()
            }
          </div>
        </>
      else
        <>
          <Gravatar email={email} customImage={customImage} shape="circle" size="xlarge" pt={gravatarPt}/>
          <div className="content-container">
            <div className="text font-bold">
              {username}:
            </div>
            <div>
              <MarkdownDisplay markdown={text} contentClass="chat-message"/>
            </div>
          </div>
        </>
    }
  </div>