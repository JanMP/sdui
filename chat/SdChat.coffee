import {Meteor} from 'meteor/meteor'
import React, {useState, useEffect, useRef} from 'react'
import {meteorApply, ActionButton} from 'meteor/janmp:sdui'
import {Fill, Bottom} from 'react-spaces'
import {InputText} from 'primereact/inputtext'
import {ScrollPanel} from 'primereact/scrollpanel'
import {useTracker, useSubscribe} from 'meteor/react-meteor-data'
import {DefaultMessage} from './DefaultMessage.coffee'
import {SdList} from '../tables/SdList'
import {SessionListItemContent} from './SessionListItemContent'
import {DefaultListItem} from '../tables/DefaultListItem'
import {Toast} from 'primereact/toast'
import {DefaultMetaDataDisplay} from './DefaultMetaDataDisplay.coffee'
import {SessionListHeader} from './SessionListHeader.coffee'
import {useTranslation} from 'react-i18next'

DefaultSessionListItem  = ({sessionId}) ->
  (args) ->  <DefaultListItem {{args..., ListItemContent: SessionListItemContent, selectedRowId: sessionId}...} />


export SdChat = ({dataOptions, className = "", customComponents = {}}) ->

  {SessionListItem, Message, MetaDataDisplay} = customComponents
  SessionListItem ?= DefaultSessionListItem
  Message ?= DefaultMessage
  MetaDataDisplay ?= DefaultMetaDataDisplay


  {bots, sourceName, sessionListDataOptions, isSingleSessionChat, metaDataCollection} = dataOptions

  [inputValue, setInputValue] = useState ''
  [sessionId, setSessionId] = useState null

  scrollAreaRef = useRef null
  toast = useRef null
  {t} = useTranslation()

  messagesAreLoading = useSubscribe "#{sourceName}.messages", {sessionId}
  metaDataIsLoading = useSubscribe "#{sourceName}.metaData", {sessionId}
  usageLimitsIsLoading = useSubscribe "#{sourceName}.usageLimits", {sessionId}

  session = useTracker ->
    (dataOptions?.sessionListDataOptions?.rowsCollection?.findOne sessionId) ? {}

  currentLimits = useTracker ->
    dataOptions?.usageLimitsCollection?.findOne {sessionId}

  getInitialSession = ->
    meteorApply
      method: "#{sourceName}.initialSessionForChat"
      data: {}
    .then setSessionId

  useEffect ->
    unless sessionId?
      getInitialSession()
    undefined
  , []

  metaData = useTracker ->
    dataOptions?.metaDataCollection?.find({sessionId}).fetch()


  useEffect ->
    console.log 'usageLimits', currentLimits
  , [currentLimits]

  messageIsTooLong = inputValue?.length > currentLimits?.maxMessageLength
  noMoreMessagesToday = currentLimits?.messagesPerDayLeft <= 0
  noMoreMessagesThisSession = currentLimits?.messagesPerSessionLeft <= 0
  noMoreSessionsToday = currentLimits?.sessionsPerDayLeft <= 0

  messages =
    useTracker ->
      dataOptions.collection.find {sessionId},
        sort: createdAt: -1
        limit: 100
      .fetch()
      .reverse()
      .map (message) ->
        user = bots.find (bot) -> bot.id is message.userId
        user ?=
          if message.userId is Meteor.userId()
            username: Meteor.user()?.username
            email: Meteor.user()?.emails?[0]?.address
        user ?= session.users.find (user) -> user.userId is message.userId
        {message..., username: user?.username, email: user?.email, customImage: user?.customImage}

  useEffect ->
    scrollAreaRef?.current?.querySelector(':scope > :last-child')?.scrollIntoView block: 'end'
  , [messages]

  handleError = (error) ->
    toast.current.show
      severity: 'error'
      summary: 'Fehler'
      detail: "#{error.message}"
    console.error error

  addMessage = (event) ->
    event.preventDefault()
    return if inputValue is ''
    if messageIsTooLong
      toast.current.show
        severity: 'error'
        summary: 'Fehler'
        detail: "Deine Nachricht ist zu lang. Bitte kürze sie auf #{maxMessageLength} Zeichen."
      return
    setInputValue ''
    meteorApply
      method: "#{sourceName}.addMessage"
      data:
        text: inputValue
        sessionId: sessionId
    .catch handleError

  # SessionList hook
  # This is a shortcut to build a single user Chat for Chatbots
  # TODO: build UI to add users to a chat
  addSession = (model = {}) ->
    meteorApply
      method: "#{sourceName}.addSession"
      data: model
    .then setSessionId
    .catch handleError

  # SessionList hook
  deleteSession = ({id}) ->
    if sessionId is id then setSessionId ''
    meteorApply
      method: "#{sourceName}.deleteSession"
      data: {id}
    .catch handleError

  resetSingleSession = ->
    meteorApply
      method: "#{sourceName}.resetSingleSession"
      data: {}
    .then setSessionId
    .catch handleError

  onSessionListRowClick = ({rowData}) ->
    setSessionId rowData._id

  <div className="h-full w-full flex flex-row gap-4 #{className}">
    <Toast ref={toast} />
    {
      unless isSingleSessionChat
        <div className="w-16rem flex-none">
          <SdList
            dataOptions={{
              sessionListDataOptions...,
              onSubmit: addSession, onDelete: deleteSession, onRowClick: onSessionListRowClick
            }}
            customComponents={
              ListItem: SessionListItem {sessionId}
              Header: SessionListHeader
            }
          />
        </div>
    }
    <div className="flex-grow-1">
      <div className="h-full flex flex-column gap-2">
        {
          if isSingleSessionChat
            <div className="flex-grow-0 flex align-items-center">
              <ActionButton
                icon="pi pi-fw pi-times"
                className="p-button-rounded p-button-text p-button-danger"
                onAction={resetSingleSession}
                disabled={noMoreSessionsToday}
              />
              {<span>{t "sdui:sessionsPerDayLimitReached", "(max Chats/Tag erreicht)"}</span> if noMoreSessionsToday}
            </div>
        }
        {<div className="p-2 bg-red-500">
          <pre>{JSON.stringify currentLimits, null, 2}</pre>
        </div> if false}
        <div className="h-1rem flex-grow-1 flex-shrink-1 overflow-y-scroll" ref={scrollAreaRef}>
          {
            messages.map (message) ->
              <Message
                key={message._id}
                message={message}/>
          }
        </div>
        <MetaDataDisplay metaData={metaData}/>
        <form onSubmit={addMessage} className="p-card p-4">
          <div className="p-inputgroup flex ">
            <InputText
              value={inputValue}
              onChange={(e) -> setInputValue e.target.value}
              style={width: '100%'}
              className={if messageIsTooLong then 'p-invalid' else ''}
              disabled={noMoreMessagesToday}
            />
            <span className="p-inputgroup-addon">
              <i className="pi pi-send" />
            </span>
          </div>
          {
            if noMoreMessagesToday
              <div className="mt-1 text-xs text-500 text-center">
                {t "sdui:messagesPerDayLimitReached", "(max Nachrichten/Tag erreicht)"}
              </div>
          }
          {
            if noMoreMessagesThisSession
              <div className="mt-1 text-xs text-500 text-center">
                {t "sdui:messagesPerSessionLimitReached", "(max Nachrichten/Sitzung erreicht)"}
              </div>
          }
        </form>
      </div>
    </div>
  </div>