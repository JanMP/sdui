import {Meteor} from 'meteor/meteor'
import React, {useState, useEffect, useRef} from 'react'
import {useTracker, useSubscribe} from 'meteor/react-meteor-data'
import {meteorApply, ActionButton, useToast} from 'meteor/janmp:sdui'
import {InputText} from 'primereact/inputtext'
import {ScrollPanel} from 'primereact/scrollpanel'
import {DefaultMessage} from './DefaultMessage.coffee'
import {SdList} from '../tables/SdList'
import {SessionListItemContent} from './SessionListItemContent'
import {DefaultListItem} from '../tables/DefaultListItem'
import {DefaultMetaDataDisplay} from './DefaultMetaDataDisplay2.coffee'
import {SessionListHeader} from './SessionListHeader.coffee'
import {Tooltip} from 'primereact/tooltip'
import {useTranslation} from 'react-i18next'


DefaultSessionListItem  = ({sessionId}) ->
  (args) ->  <DefaultListItem {{args..., ListItemContent: SessionListItemContent, selectedRowId: sessionId}...} />


defaultProcessMessageText = ({text, metaData, addLinkedMetaData}) ->
  return '' unless typeof text is 'string'
  replacer = (match, title, url) ->
    metaDataItem = metaData?.find((m) -> m.data?.url is url)
    if metaDataItem?
      id = metaDataItem._id
      addLinkedMetaData id
      "<a class='text-primary-500' id='#{id}' href='#{url}' target='_blank'>#{title}</a>"
    else
      "<a class='text-blue-500' href='#{url}' target='_blank'>#{title}</a>"
  text
  ?.replace /\[(.+?)\]\((.+?)\)/g, replacer
  ?.replace /\[(.+?)\]\(([^\)]+?)$/g, (match, title, url) -> "[#{title}]() ... <span class='pi pi-spin text-primary-200 pi-spinner'/>"


export SdChat = ({dataOptions, className = "", customComponents = {}, processMessageText, showTools = true}) ->

  {SessionListItem, Message, MetaDataDisplay} = customComponents
  SessionListItem ?= DefaultSessionListItem
  Message ?= DefaultMessage
  MetaDataDisplay ?= DefaultMetaDataDisplay

  displayMetaData = true

  processMessageText ?= defaultProcessMessageText

  {bots, sourceName, sessionListDataOptions, isSingleSessionChat, metaDataCollection} = dataOptions

  [inputValue, setInputValue] = useState ''
  [sessionId, setSessionId] = useState null

  scrollAreaRef = useRef null
  toast = useToast()
  linkedMetaData = useRef new Set()
  addLinkedMetaData = (id) -> linkedMetaData.current.add id

  {t} = useTranslation()

  messagesAreLoading = useSubscribe "#{sourceName}.messages", {sessionId}
  metaDataIsLoading = useSubscribe "#{sourceName}.metaData", {sessionId}
  usageLimitsIsLoading = useSubscribe "#{sourceName}.usageLimits", {sessionId}

  session = useTracker ->
    (dataOptions?.sessionListDataOptions?.rowsCollection?.findOne sessionId) ? {}

  currentLimits = useTracker ->
    dataOptions?.usageLimitCollection?.findOne()

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

  messageIsTooLong = inputValue?.length > currentLimits?.maxMessageLength
  noMoreMessagesToday = currentLimits?.messagesPerDayLeft <= 0
  noMoreMessagesThisSession = currentLimits?.messagesPerSessionLeft <= 0
  noMoreSessionsToday = currentLimits?.sessionsPerDayLeft <= 0

  messages =
    useTracker ->
      dataOptions.messageCollection.find {sessionId},
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
        text = processMessageText {text: message.text, metaData, addLinkedMetaData}
        {message..., text,  username: user?.username, email: user?.email, customImage: user?.customImage}

  useEffect ->
    if scrollAreaRef?.current and messages.length > 0
      scrollAreaRef.current.scrollTop = scrollAreaRef.current.scrollHeight
    return
  , [messages]

  handleError = (error) ->
    toast.show
      severity: 'error'
      summary: 'Fehler'
      detail: "#{error.message}"
    console.error error

  addMessage = (event) ->
    event.preventDefault()
    return if inputValue is ''
    if messageIsTooLong
      toast.show
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

  setFeedBackHandlerForMessage = (messageId) -> (feedback) ->
    console.log 'setFeedBackHandlerForMessage', {messageId, feedback}
    meteorApply
      method: "#{sourceName}.setFeedBackForMessage"
      data:
        messageId: messageId
        feedback: feedback
    .catch handleError

  # SessionList hook
  addSession = (model = {}) ->
    meteorApply
      method: "#{sourceName}.addSession"
      data: model
    .then setSessionId
    .catch handleError

  # SessionList hook
  deleteSession = ({id}) ->
    if sessionId is id then setSessionId null
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

  setClassForLimit = (limit) ->
    switch
      when limit <= 1  then 'fadein animation-duration-500 animation-iteration-infinite text-red-500'
      when limit <= 2  then 'text-red-500'
      when limit <= 3  then 'text-orange-500'
      when limit <= 4 then 'text-orange-800'
      else ''

  header =
    <div
      style={
        display: 'flex'
        alignItems: 'center'
        justifyContent: 'space-between'
        gridArea: 'header'
      }
    >
      {
        if isSingleSessionChat
          <ActionButton
            label="Neuer Chat"
            icon="pi pi-fw pi-refresh"
            className="p-button-rounded p-button-sm p-button-outlined p-button-primary"
            onAction={resetSingleSession}
            disabled={noMoreSessionsToday}
          />
      }
      <div className="p-2 text-sm">
        Noch übrig:
        <span className={setClassForLimit currentLimits?.messagesPerDayLeft}> {currentLimits?.messagesPerDayLeft} Msgs/Tag,</span>
        <span className={setClassForLimit currentLimits?.messagesPerSessionLeft}> {currentLimits?.messagesPerSessionLeft} Msgs/Chat,</span>
        <span className={setClassForLimit currentLimits?.sessionsPerDayLeft}> {currentLimits?.sessionsPerDayLeft} Chats/Tag</span>
      </div>
    </div>

  sessionListDisplay =
   <div
     style={
       gridArea: 'sidebar'
       width: '100%'
       height: '100%'
       overflowY: 'none'
     }
   >
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

  {areas, columns} =
    if isSingleSessionChat
      if displayMetaData
        areas: "'content metadata'"
        columns: '2fr 1fr'
      else
        areas: "'content'"
        columns: '1fr'
    else
      if displayMetaData
        areas: "'sidebar content metadata'"
        columns: '16rem 2fr 1fr'
      else
        areas: "'sidebar content'"
        columns: '1fr 3fr'

  # CSS Grid layout with variables
  containerStyle =
    height: '100%'
    width: '100%'
    display: 'grid'
    gridTemplateAreas: areas
    gridTemplateColumns: columns
    gridTemplateRows: '1fr'
    "--sidebar-width": '16rem'
    "--metadata-width": '32rem'
    "--header-height": '4rem'
    "--input-height": '4rem'
    "--grid-gap": '0.5rem'

  contentStyle =
    gridArea: 'content'
    display: 'grid'
    gridTemplateAreas: "'header' 'messages' 'input'"
    gridTemplateRows: 'var(--header-height) 1fr var(--input-height)'
    height: '100%'
    padding: 'var(--grid-gap)'

  messagesStyle =
    gridArea: 'messages'
    height: '100%'
    maxHeight: '100%'
    padding: 'var(--grid-gap)'

  inputFormStyle =
    gridArea: 'input'
    padding: 'var(--grid-gap)'

  metaDataStyle =
    gridArea: 'metadata'
    position: 'relative'
    padding: 'var(--grid-gap)'
    overflow: 'none'

  # return
  <div className={className} style={containerStyle}>
    {
      unless isSingleSessionChat
        sessionListDisplay
    }
    <div style={contentStyle}>
      {header}

      <div className="relative" style={messagesStyle}>
        <div className="absolute top-0 left-0 right-0 bottom-0 overflow-y-auto" ref={scrollAreaRef}>
          {
            messages.map (message) ->
              <Message
                key={message._id}
                message={message}
                metaData={metaData}
                onChangeFeedback={setFeedBackHandlerForMessage message._id}
                showTools={showTools}
              />
          }
        </div>
      </div>

      <form onSubmit={addMessage} className="p-card" style={inputFormStyle}>
        <div className="p-inputgroup">
          <InputText
            value={inputValue}
            onChange={(e) -> setInputValue e.target.value}
            style={width: '100%'}
            className={if messageIsTooLong then 'p-invalid' else ''}
            disabled={noMoreMessagesToday or noMoreMessagesThisSession}
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

    {
      if displayMetaData
        <div style={metaDataStyle}>
          <MetaDataDisplay metaData={metaData}/>
        </div>
    }
  </div>

