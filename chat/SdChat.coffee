import React, {useState, useEffect, useRef} from 'react'
import {meteorApply} from 'meteor/janmp:sdui'
import {Fill, Bottom} from 'react-spaces'
import {InputText} from 'primereact/inputtext'
import {ScrollPanel} from 'primereact/scrollpanel'
import {useTracker, useSubscribe} from 'meteor/react-meteor-data'
import {Message} from './Message.coffee'
import {SdList} from '../tables/SdList'
import {SessionListItemContent} from './SessionListItemContent'
import {DefaultListItem} from '../tables/DefaultListItem'
import {toast} from 'react-toastify'

SessionListItem  = ({sessionId}) ->
  (args) ->  <DefaultListItem {{args..., ListItemContent: SessionListItemContent, selectedRowId: sessionId}...} />

export SdChat = ({dataOptions}) ->

  {bots, sourceName, sessionListDataOptions} = dataOptions

  [inputValue, setInputValue] = useState ''
  [sessionId, setSessionId] = useState null

  scrollAreaRef = useRef null

  sessionsAreLoading = useSubscribe "#{sourceName}.sessions"
  messagesAreLoading = useSubscribe "#{sourceName}.messages", {sessionId}

  session = useTracker ->
    dataOptions.sessionListDataOptions.rowsCollection.findOne sessionId

  useEffect ->
    meteorApply
      method: "#{sourceName}.initialSessionForChat"
      data: {}
    .then setSessionId
    undefined
  , []

  messages =
    useTracker ->
      return [] unless session?.userIds?
      dataOptions.collection.find {},
        sort: createdAt: -1
        limit: 100
      .fetch()
      .reverse()
      .map (message) ->
        user = bots.find (bot) -> bot.id is message.userId
        user ?= session.users.find (user) -> user.userId is message.userId
        {message..., username: user?.username, email: user?.email, customImage: user?.customImage}

  useEffect ->
    scrollAreaRef?.current?.querySelector(':scope > :last-child')?.scrollIntoView()
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

  # This is a shortcut to build a single user Chat for Chatbots
  # TODO: build UI to add users to a chat
  onSubmit = (model) ->
    meteorApply
      method: "#{sourceName}.addSession"
      data: model
    .then setSessionId
    .catch (error) ->
      toast.error "#{error}"
      console.log error

  onDelete = ({id}) ->
    if sessionId is id then setSessionId ''
    meteorApply
      method: "#{sourceName}.deleteSession"
      data: {id}
    .catch (error) ->
      toast.error "#{error}"
      console.error error

  onSessionListRowClick = ({rowData}) ->
    setSessionId rowData._id

  <div className="h-full w-full flex flex-row gap-4">
    <div className="w-16rem flex-none">
      <SdList
        dataOptions={{sessionListDataOptions..., onSubmit, onDelete, onRowClick: onSessionListRowClick}}
        customComponents={ListItem: SessionListItem {sessionId}}
      />
    </div>
    <div className="flex-grow-1">
      <div className="h-full flex flex-column gap-2">
        <div className="h-30rem flex-grow-1 flex-shrink-1 overflow-y-scroll" ref={scrollAreaRef}>
          {messages.map (message) ->
            <Message
              key={message._id}
              message={message}/>
          }
        </div>
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