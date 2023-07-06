import React, {useState, useEffect} from 'react'
import {meteorApply} from 'meteor/janmp:sdui'
import {Fill, Bottom} from 'react-spaces'
import {InputText} from 'primereact/inputtext'
import {useTracker, useSubscribe} from 'meteor/react-meteor-data'
import {Message} from './Message.coffee'
import {SdList} from '../tables/SdList'
import {SessionListItemContent} from './SessionListItemContent'
import {DefaultListItem} from '../tables/DefaultListItem'
import {toast} from 'react-toastify'

SessionListItem  = ({sessionId}) ->
  (args) ->  <DefaultListItem {{args..., ListItemContent: SessionListItemContent, selectedRowId: sessionId}...} />

export SdChat = ({dataOptions}) ->

  {sourceName, sessionListDataOptions} = dataOptions

  [inputValue, setInputValue] = useState ''
  [sessionId, setSessionId] = useState 'QzDv3XpCHn42RkQLF'

  sessionsAreLoading = useSubscribe "#{sourceName}.sessions"
  messagesAreLoading = useSubscribe "#{sourceName}.messages", {sessionId}

  session = useTracker ->
    dataOptions.sessionListDataOptions.rowsCollection.findOne sessionId

  messages =
    useTracker ->
      return [] unless session?.userIds?
      dataOptions.collection.find {},
        sort: createdAt: 1
        limit: 100
      .map (message) ->
        user = session.users.find (user) -> user.userId is message.userId
        {message..., username: user?.username, email: user?.email}

  console.log messages
  addMessage = (event) ->
    event.preventDefault()
    return if inputValue is ''
    meteorApply
      method: "#{sourceName}.addMessage"
      data:
        text: inputValue
        sessionId: sessionId
    .then ->
      setInputValue ''

  # This is a shortcut to build a single user Chat for Chatbots
  # TODO: build UI to add users to a chat
  onSubmit = (model) ->
    meteorApply
      method: "#{sourceName}.sessions.addSingleUserSession"
      data: model
    .then setSessionId
    .catch (error) ->
      toast.error "#{error}"
      console.log error

  onDelete = ({id}) ->
    if sessionId is id then setSessionId ''
    meteorApply
      method: "#{sourceName}.sessions.deleteSession"
      data: {id}
    .catch (error) ->
      toast.error "#{error}"
      console.log error

  onSessionListRowClick = ({rowData}) ->
    setSessionId rowData._id

  <div className="h-full flex gap-2">
    <div className="h-full w-15rem">
      <SdList
        dataOptions={{sessionListDataOptions..., onSubmit, onDelete, onRowClick: onSessionListRowClick}}
        customComponents={ListItem: SessionListItem {sessionId}}
      />
    </div>
    <div className="h-full w-full flex flex-column">
      <div className="h-full flex flex-column gap-2 overflow-y-scroll">
        {messages.map (message) ->
          <Message
            message={message}/>
        }
      </div>
      <form onSubmit={addMessage} className="bottom-container">
        <InputText
          value={inputValue}
          onChange={(e) -> setInputValue e.target.value}
          style={width: '100%'}
        />
      </form>
    </div>
  </div>