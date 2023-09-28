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

  sessionsAreLoading = useSubscribe "#{sourceName}.sessions"
  messagesAreLoading = useSubscribe "#{sourceName}.messages", {sessionId}
  metaDataIsLoading = useSubscribe "#{sourceName}.metaData", {sessionId}

  session = useTracker ->
    dataOptions?.sessionListDataOptions?.rowsCollection?.findOne sessionId

  getNewSession = ->
    meteorApply
      method: "#{sourceName}.initialSessionForChat"
      data: {}
    .then setSessionId

  useEffect ->
    unless sessionId?
      getNewSession()
    undefined
  , []

  metaData = useTracker ->
    dataOptions?.metaDataCollection?.find({sessionId}).fetch()
  
  messages =
    useTracker ->
      dataOptions.collection.find {},
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

  addMessage = (event) ->
    event.preventDefault()
    return if inputValue is ''
    setInputValue ''
    meteorApply
      method: "#{sourceName}.addMessage"
      data:
        text: inputValue
        sessionId: sessionId
    .catch (error) ->
      toast.current.show
        severity: 'error'
        summary: 'Fehler'
        detail: "#{error.message}"
      console.error error

  # SessionList hook
  # This is a shortcut to build a single user Chat for Chatbots
  # TODO: build UI to add users to a chat
  onSubmit = (model) ->
    meteorApply
      method: "#{sourceName}.addSession"
      data: model
    .then setSessionId
    .catch (error) ->
      toast.current.show
        severity: 'error'
        summary: 'Fehler'
        detail: "#{error.message}"
      console.log error

  # SessionList hook
  onDelete = ({id}) ->
    if sessionId is id then setSessionId ''
    meteorApply
      method: "#{sourceName}.deleteSession"
      data: {id}
    .catch (error) ->
      toast.current.show
        severity: 'error'
        summary: 'Fehler'
        detail: "#{error.message}"
      console.error error


  onSessionListRowClick = ({rowData}) ->
    setSessionId rowData._id

  <div className="h-full w-full flex flex-row gap-4 #{className}">
    <Toast ref={toast} />
    {
      unless isSingleSessionChat
        <div className="w-16rem flex-none">
          <SdList
            dataOptions={{sessionListDataOptions..., onSubmit, onDelete, onRowClick: onSessionListRowClick}}
            customComponents={ListItem: SessionListItem {sessionId}}
          />
        </div>
    }
    <div className="flex-grow-1">
      <div className="h-full flex flex-column gap-2">
        {
          if isSingleSessionChat
            <div className="flex-grow-0">
              <ActionButton
                icon="pi pi-fw pi-times"
                className="p-button-rounded p-button-text p-button-danger"
                method="#{sourceName}.resetSingleSession"
              />
            </div>
        }
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
          <div className="p-inputgroup">
            <InputText
              value={inputValue}
              onChange={(e) -> setInputValue e.target.value}
              style={width: '100%'}
            />
            <span className="p-inputgroup-addon">
              <i className="pi pi-send" />
            </span>
          </div>
        </form>
      </div>
    </div>
  </div>