import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {HumanMessage, AIMessage, SystemMessage, ToolMessage} from "@langchain/core/messages"
import {concat} from "@langchain/core/utils/stream"
# import {ChatAnthropic} from '@langchain/anthropic'
# import {ChatOpenAI} from '@langchain/openai'
# import {ChatMistralAI} from '@langchain/mistralai'
import _ from 'lodash'

allowedChatClients = ['ChatAnthropic', 'ChatOpenAI', 'ChatMistralAI']


###*
  @param {Object} options
  @param {Object} options.chatClient - the langchain instance for the chat client
  @param {String} [options.getSystemPrompt=() => null] - an optional function that returns the system message the bot will recive as first message
  @param {Function} [options.getTools=({sessionId = null}) => []] - a function that returns an array of tools that can be called by the bot
  @param {Mongo.Collection} options.messageCollection
  @param {Object} [options.botUserData] - the user data for the bot
  ###
export createChatBot = ({
  chatClient,
  getSystemPrompt,
  getTools = ({sessionId = null}) -> []
  messageCollection,
  botUserData
}) ->

  return unless Meteor.isServer

  unless (chatClientName = chatClient.constructor.name) in allowedChatClients
    throw new Meteor.Error 'createChatBot: chatClient must be a ChatAnthropic or ChatOpenAI or ChatMistralAI instance'

  unless messageCollection?
    throw new Meteor.Error 'createChatBot: messageCollection is required'

  handleStream = ({response, messageStubId}) ->
    done = false
    content = ''
    oldContent = ''
    finishReason = null

    updateContent = ->
      if content isnt oldContent
        oldContent = content
        updateMessageStub {messageStubId, text: content}
      if oldContent isnt content
        oldContent = content
        updateMessageStub {messageStubId, text: content}
    
    interval = Meteor.setInterval updateContent, 700

    for await chunk from response
      gathered = if gathered? then concat(gathered, chunk) else chunk

      switch chatClientName
        when 'ChatAnthropic'
          finishReason = chunk?.additional_kwargs?.stop_reason
          if chunk.content?[0]?.text?
            content = content + chunk.content[0].text
        when 'ChatOpenAI'
          finishReason = chunk?.response_metadata?.finish_reason
          content = content + chunk.content
        when 'ChatMistralAI'
          content = content + chunk.content
          # mistral does not have an explicit finish_reason, instead, the last chunk will contain a usage_metadata field.
          finishReason =
            if chunk.usage_metadata? then 'end_turn'
            else if chunk.tool_calls.length > 0 then 'tool_use'
        else
          throw new Meteor.Error "handleStream: unsupported chatClientName #{chatClientName}"
      
      if finishReason
        done = true
        updateMessageStub {messageStubId, tools: gathered.tool_calls}
        switch chatClientName
          when 'ChatAnthropic', 'ChatMistralAI'
            unless finishReason in ['tool_use', 'end_turn']
              throw new Meteor.Error "handleStream: finish_reason #{finishReason}"
          when 'ChatOpenAI'
            unless finishReason in ['tool_use', 'stop', 'tool_calls']
              throw new Meteor.Error "handleStream: finish_reason #{finishReason}"
          else
            throw new Meteor.Error "handleStream: unsupported chatClientName #{chatClientName}"

    new Promise (resolve) ->
      if done
        updateContent()
        Meteor.clearInterval interval
        resolve gathered

  ###*
    Build the context for the chatbot call
    @param {Object} options
    @param {String} options.sessionId
    @param {Array} [options.history] - if provided the history will be used instead of the database
    @param {Number} [options.limit=15] - the number of messages to include in the context
    @returns {Promise<Object>}
    ###
  buildContext =  ({sessionId, history = undefined, limit = 15}) ->
    # @ts-ignore, ts does not get the existential operator for the function call
    systemPrompt = (await getSystemPrompt?()) ? 'Du bist ein freundlicher, hilfreicher Chatbot'

    query =
      sessionId: sessionId
      chatRole: $ne: 'log'
      # workInProgress: $ne: true

    history ?=
      _(await messageCollection.find query,
        sort: {createdAt: 1}
        limit: limit
      .fetchAsync())
      .value()

    contextBody =
      _(history)
      .map (message, i, messages) ->
        switch
          when message.chatRole is 'system'
            new SystemMessage message.text
          when message.chatRole is 'user'
            new HumanMessage message.text
          when message.chatRole is 'function'
            switch chatClientName
              when "ChatAnthropic"
                new HumanMessage
                  content: [{
                      type: 'tool_result'
                      content: message.text
                      tool_use_id: message.tool_id #message.tool_use_id
                    }]
              when "ChatOpenAI", "ChatMistralAI"
                new ToolMessage
                  content: message.text
                  tool_call_id: message.tool_id
              else
                throw new Error "Unsupported model vendor: #{chatClientName}"
          when message.chatRole is 'assistant'
            return null if i is 0 # skip welcome (anthropic dies if user isnt first in history)
            return null if i is messages.length - 1 and message.workInProgress
            new AIMessage
              content: message.text
              tool_calls: message.tools
          else
            throw new Meteor.Error 'buildContext: unknown chatRole: ' + message.chatRole
      .flatten()
      .compact()
      # .filter (message) -> message.content?.length
      .value()
    [(new SystemMessage systemPrompt), contextBody...]


  ###*
    @description
    - create a new message stub
    - sets createdAt, chatRole to 'assistant'
    - and workInProgress to 'true
    @param {Object} options
    @param {String} options.sessionId
    @param {String} [options.text='']
    @param {String} [options.followMessageId] - if provided the new message will have a creation date right after the message to follow
    @returns {Promise<String>} the id of the new message stub
    ###
  createMessageStub = ({sessionId, text = '', followMessageId = undefined}) ->
    createdAt  = if followMessageId?
      followMessage = await messageCollection.findOneAsync followMessageId
      new Date(followMessage.createdAt.getTime() + 1)
    else
      new Date()

    messageCollection.insertAsync
      userId: botUserData.id
      sessionId: sessionId
      text: text
      chatRole: 'assistant'
      createdAt: createdAt
      workInProgress: true


  # we are not using this
  ###*
    @description
    - sets createdAt to new Date()
    - sets text to the new text
    @param {Object} options
    @param {String} options.messageStubId
    @param {String} [options.text]
    @param {Object} [options.tools]
    @returns {Promise<void>} Resolves when the message is successfully sent
  ###
  updateMessageStub = ({messageStubId, text, tools}) ->
    messageCollection.updateAsync messageStubId,
      $set:
        text: text
        tools: tools


  
  ###*
    @description
    - sets createdAt to new Date()
    - and workInProgress to 'false
    @param {Object} options
    @param {String} options.messageStubId
    @param {String} options.text
    @param {Object} [options.tools]
    @param {Object} [options.usage]
    @returns {String} the id of the Message
    ###
  finalizeMessageStub = ({messageStubId, text, tools, usage}) ->
    usage?.model ?= chatClient.model
    messageCollection.updateAsync messageStubId,
      $set:
        text: text
        tools: tools
        usage: usage
        workInProgress: false


  ###*
  * Creates and inserts a log message into the message collection.
  * @param {Object} options - The options for creating the log message.
  * @param {string} options.sessionId - The ID of the session.
  * @param {string} [options.text] - The text content of the message.
  * @param {Object} [options.toolCall] - Information about a tool call, if applicable.
  * @param {Error} [options.error] - An error object, if an error occurred.
  * @param {Object} [options.usage] - Usage statistics for the message.
  * @returns {Promise<Object>} A promise that resolves with the inserted document.
    ###
  createLogMessage = ({sessionId, text = undefined, toolCall = undefined, error = undefined, usage = undefined}) ->
    messageCollection.insertAsync
      userId: botUserData.id
      sessionId: sessionId
      text: text
      toolCall: toolCall
      error: error
      chatRole: 'log'
      createdAt: new Date()
      workInProgress: false
      usage: usage

  ###*
    Call the chatbot handle the response and function calls
    @param {Object} options
    @param {String} options.sessionId
    @param {String} options.messageStubId - the id of the message stub
    @param {Array} options.context - the result of buildContext
    @param {Boolean} [options.allowFunctionCall=true] - if false, the bot will not call any functions
    @returns {Promise<String>} the id of the final message
    ###
  call = ({sessionId, messageStubId, context}) ->
    console.log 'call', {sessionId, messageStubId, context}
    tools = getTools {sessionId, messageId: messageStubId}
    
    chatClient
    .bindTools tools.map (f) -> _.omit f, 'run'
    .stream context
    .then (response) ->
      handleStream {response, messageStubId}
    .catch (error) ->
      console.error error
    .then (response) ->
      console.log 'response', response
      usage =
        model: chatClient.model
        prompt: pt = response.usage_metadata.input_tokens
        completion: ct = response.usage_metadata.output_tokens
        total: pt + ct

      text = if chatClientName in ["ChatOpenAI", "ChatMistralAI"]
        response.content
      else if chatClientName is "ChatAnthropic"
        response.content[0].text

      toolCalls = response?.tool_calls
      finalizeMessageStub {messageStubId, text, tools: toolCalls, usage}

      if toolCalls? and toolCalls.length
        await Promise.allSettled toolCalls.map (tc) ->
          return unless tc.args?
          
          # createLogMessage {sessionId, toolCall: tc, usage}
          tool_selected = (tools.find (t) -> t.function.name is tc.name)
          result = await tool_selected?.run tc.args
          await messageCollection.insertAsync
            userId: botUserData.id
            sessionId: sessionId
            chatRole: 'function'
            createdAt: new Date()
            workInProgress: false
            text: result
            tool_id: tc.id
            args: tc.args
            function_name: tc.name
        
        contextWithResult = await buildContext {sessionId}

        # create a new message for the answer of the chatbot to the function call result.
        console.log 'newMessageId', newMessageId = await createMessageStub {sessionId, text: '...'}
        call {sessionId, messageStubId: newMessageId, context: contextWithResult}
    .catch (error) ->
      createLogMessage {sessionId, error: error}
      throw error

  {call, createMessageStub, updateMessageStub, finalizeMessageStub, buildContext}