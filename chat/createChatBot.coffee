import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import _ from 'lodash'
import { tool } from "@langchain/core/tools";
import { z } from "zod";
import { ChatPromptTemplate, PromptTemplate } from "@langchain/core/prompts";
import { HumanMessage, AIMessage, SystemMessage } from "@langchain/core/messages";
import { concat } from "@langchain/core/utils/stream";
countTokens = (messages) ->
  messages
  .map (m) -> tokenizer.encode m.content ? ''
  .reduce ((a, b) -> a + b.length), 0


addTool = tool(
  (input) ->
    new Promise((resolve, reject) ->
      try
        resolve(input.a + input.b)
      catch error
        reject(error)
    )
  ,
  name: "add"
  description: "Adds a and b."
  schema: z.object(
    a: z.number()
    b: z.number()
  )
)


###*
  @param {Object} options
  @param {Object} options.chatClient - the js chat clearInterval
  @param {Object} options.chatClientLangChain - the language chain for the chat client
  @param {Boolean} options.stream - if true, the bot will stream its response
  @param {String} options.model - the model name to use
  @param {String} options.getSystemPrompt - a function that returns the system message the bot will ALLWAYS recive as first message
  @param {Function} [options.getTools=({sessionId = null}) => []] - a function that returns an array of tools that can be called by the bot
  @param {String} [options.toolChoice] - the function call mode
  @param {Object} [options.options={}] - additional options for the llm call
  @param {Number} [options.contextTokenLimit=8191 - 2000] - the token limit for the context
  @param {Boolean} [options.allowRecursiveToolCalls=false] - if true, the bot may call tools on 2nd call
  @param {Mongo.Collection} options.messageCollection
  @param {Object} [options.botUserData] - the user data for the bot
  ###
export createChatBot = ({
  model_type,
  chatClient,
  chatClientLangChain,
  stream = false,
  model, getSystemPrompt,
  getTools = ({sessionId = null}) -> []
  toolChoice,
  options = {}
  contextTokenLimit = 8191 - 2000
  allowRecursiveToolCalls = false
  messageCollection,
  botUserData
}) ->
  return unless Meteor.isServer

  # if model_type not in ['openai', 'anthropic']
  #   throw new Meteor.Error 'createChatBot: model_type must be "openai" or "anthropic"'


  if chatClientLangChain
    modelWithTools = chatClientLangChain.bindTools([addTool])

  unless messageCollection?
    throw new Meteor.Error 'createChatBot: messageCollection is required'

  handleStream = ({response, messageStubId}) ->
    done = false
    content = ''
    oldContent = ''
    finishReason = null
    objectFromDeltas = {}
    toolCalls = []
    usage = {}

    addDelta = ({objectFromDeltas, delta}) ->
      for key of delta
        objectFromDeltas[key] = switch
          when key is 'tool_calls'
            for toolCallChunk in delta.tool_calls # special handling of tool_calls
              if toolCalls.length <= toolCallChunk.index
                toolCalls.push
                  id: ''
                  type: 'function'
                  function:
                    name: ''
                    arguments: ''
              toolCall = toolCalls[toolCallChunk.index]
              if toolCallChunk.id?
                toolCall.id += toolCallChunk.id
              if toolCallChunk.function?.name?
                toolCall.function.name += toolCallChunk.function.name
              if toolCallChunk.function?.arguments?
                toolCall.function.arguments += toolCallChunk.function.arguments
          when delta[key] is null then null
          when typeof delta[key] is 'string'
            (objectFromDeltas?[key] ? '') + delta[key]
          when typeof delta[key] is 'object'
            addDelta {objectFromDeltas: (objectFromDeltas?[key] ? {}), delta: delta[key]}
          else
            throw new Meteor.Error "handleStream: addDelta: unknown type #{typeof delta[key]}"
      objectFromDeltas

    updateContent = ->
      if oldContent isnt content
        oldContent = content
        messageCollection.updateAsync messageStubId,
          $set:
            text: content
            createdAt: new Date()
            workInProgress: true
    
    interval = Meteor.setInterval updateContent, 700

    for await chunk from response
      try
        gathered = if gathered? then concat(gathered, chunk) else chunk

        # delta = chunk?.choices?[0]?.delta


        # for anthropic
        if model_type is 'anthropic'
          finishReason = chunk?.additional_kwargs?.stop_reason
          usage = chunk?.additional_kwargs?.usage
          if chunk.content?[0]?.text?
            console.log chunk.content[0].text
            content = content + chunk.content[0].text
        
        # for openai
        if model_type is 'openai'
          finishReason = chunk?.response_metadata?.finish_reason      
          content = content + chunk.content
          usage = chunk.usage_metadata

        
        # console.log 'delta', JSON.stringify delta, null, 2
        if finishReason
          done = true
          if model_type is 'anthropic'
            unless finishReason in ['tool_use', 'end_turn']
              throw new Meteor.Error "handleStream: finish_reason #{finishReason}"
          else if model_type is 'openai'
            unless finishReason in ['tool_use']
              throw new Meteor.Error "handleStream: finish_reason #{finishReason}"
            

        # if gathered.tool_call_chunks?.length > 0
        #   console.log gathered.tool_call_chunks[0]?.args? 
      catch error
        done = true
        throw new Meteor.Error "handleStream: #{error.message}"

    new Promise (resolve) ->
      if done
        updateContent()
        Meteor.clearInterval interval
        resolve gathered

  ###*
    Build the context for the chatbot call
    @param {Object} options
    @param {String} options.sessionId
    @param {Array} [options.additionalMessages=[]]
    @param {Number} [options.initialLimit=15]
    @example
      chatBot.buildContext
        sessionId: '123'
        additionalMessages: [{content: 'Talk like a Pirate! Harrr!', role: 'system'}]
        initialLimit: 20
    ###
  buildContext =  ({sessionId, additionalMessages = [], initialLimit = 15}) ->
    fetchedSystemPrompt = getSystemPrompt?()
    system = if typeof fetchedSystemPrompt is 'string' then fetchedSystemPrompt else "Du bist ein freundlicher, hilfreicher Chatbot"
    query =
      sessionId: sessionId
      workInProgress: $ne: true
      chatRole: $ne: 'log'
    history =
      (await messageCollection.find query,
        sort: {createdAt: -1}
        limit: initialLimit
      .fetchAsync())
      .filter (message) -> message.text? or message.results?
      .reverse()
      .map (message) ->
        if message.chatRole is 'system'
          msg = new SystemMessage message.text
        else if message.chatRole is 'user'
          msg = new HumanMessage message.text
        else if message.chatRole is 'function'
          msg = new HumanMessage 'The result of the function is' + message.results
          console.log 'function message', msg
        else if message.chatRole is 'assistant'
          msg = new AIMessage message.text
        console.log 'message', msg
        msg
        # else if message.chatRole is 'log'
          
        # else
        #   console.error "buildContext: unknown chatRole #{message.chatRole}"
    build = (limit) -> # TODO we don't have the tokenizer anymore, this whole aproach needs to be reworked
      if limit < 0
        throw new Meteor.Error 'buildHistory: limit must be >= 0'
      croppedHistory = history[0..limit]
      system_msg = new SystemMessage system
      messages = [system_msg, additionalMessages..., croppedHistory...]
      # console.log 'buildHistory: messages', messages
      console.log 'buildHistory: messages', messages
      try
        if tokenizer.isWithinTokenLimit messages, contextTokenLimit
          messages
        else
          console.log 'buildHistory: tokenLimit reached, trying again with limit ', limit - 1
          build limit - 1
      catch error
        console.error "The tokenizer is broken: #{error.message}"
        messages
    build initialLimit


  ###*
    @description
    - create a new message stub
    - sets createdAt, chatRole to 'assistant'
    - and workInProgress to 'true
    @param {Object} options
    @param {String} options.sessionId
    @param {String} [options.text='']
    @returns {String} the id of the new message stub
    ###
  createMessageStub = ({sessionId, text = ''}) ->
    messageCollection.insertAsync
      userId: botUserData.id
      sessionId: sessionId
      text: text
      chatRole: 'assistant'
      createdAt: new Date()
      workInProgress: true

  ###*
    @description
    - sets createdAt to new Date()
    - sets text to the new text
    ###
  updateMessageStub = ({messageId, text}) ->
    messageCollection.updateAsync messageId,
      $set:
        text: text
        createdAt: new Date()

  ###*
    @description
    - sets createdAt to new Date()
    - and workInProgress to 'false
    @param {Object} options
    @param {String} options.messageId
    @param {String} options.text
    @param {Object} [options.usage]
    @returns {String} the id of the Message
    ###
  finalizeMessageStub = ({messageId, text, usage}) ->
    messageCollection.updateAsync messageId,
      $set:
        createdAt: new Date()
        workInProgress: false
        text: text
        usage: usage

  createSystemMessage = ({sessionId, text, usage = undefined}) ->
    messageCollection.insertAsync
      userId: botUserData.id
      sessionId: sessionId
      text: text
      chatRole: 'system'
      createdAt: new Date()
      workInProgress: false
      usage: usage
    
  createAIMessage = ({sessionId, text, usage = undefined}) ->
    messageCollection.insertAsync
      userId: botUserData.id
      sessionId: sessionId
      text: text
      chatRole: 'assistant'
      createdAt: new Date()
      workInProgress: false
      usage: usage

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


  createFunctionMessage = ({sessionId, args, results}) ->
    messageCollection.insertAsync
      userId: botUserData.id
      sessionId: sessionId
      chatRole: 'function'
      createdAt: new Date()
      workInProgress: false
      args: args
      results: results




  ###*
    Call the chatbot handle the response and functioncalls
    @param {Object} options
    @param {String} options.sessionId
    @param {String} options.messageId - the id of the message stub
    @param {Array} options.messages
    @param {Boolean} [options.allowFunctionCall=true] - if false, the bot will not call any functions
    @example
      chatBot.call
        sessionId: '123'
        messages: [{content: 'Hallo', role: 'user'}]
    ###
  call = ({sessionId, messageId, messages, allowFunctionCall = true}) ->

    modelWithTools = chatClientLangChain.bindTools([addTool])

    
    # toolsWithRun = getTools({sessionId, messageId})
    tools = [addTool] # toolsWithRun.map (f) -> _.omit f, 'run'

    

      # model, messages, options...,
      # tools: if allowFunctionCall then tools,
      # tool_choice: if allowFunctionCall then toolChoice,
      # stream_options: if stream then include_usage: true
    

    modelWithTools.stream messages
    .then (response) ->
      handleStream {response, messageStubId: messageId}
    .then (response) ->

      console.log response
      prompt_tokens = response.usage_metadata.input_tokens
      completion_tokens = response.usage_metadata.output_tokens

      if model_type is "openai"
        content = response.content
      else if model_type is "anthropic"
        content = response.content[0].text 


      usage =
        model: model
        prompt: prompt_tokens
        completion: completion_tokens
      unless (toolCalls = response?.tool_calls)? and toolCalls.length 
        finalizeMessageStub {messageId, text: content, usage}
      else
        Promise.allSettled toolCalls.map (tc) ->
          console.log tc
          return unless tc.args?
          
          createLogMessage {sessionId, toolCall: tc, usage}
          (tools.find (t) -> t.getName() is tc.name)?.invoke tc.args
        .then (result) ->
          console.log "called function with result", result
          return unless result?


          createFunctionMessage {sessionId, results: JSON.stringify result, args: 1}
          # anthropic doesnt allow for system messages in the middle.
          messagesWithResult = await buildContext {sessionId}
          
          console.log 'messagesWithResult', messagesWithResult
          call {sessionId, messageId: messageId, messages: messagesWithResult, allowFunctionCall: allowRecursiveToolCalls}
    .catch (error) ->
      createLogMessage {sessionId, error: error}
      throw error

  {call, createMessageStub, updateMessageStub, finalizeMessageStub, buildContext}