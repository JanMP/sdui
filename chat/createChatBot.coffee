import {Meteor} from 'meteor/meteor'
import {setupOpenAIApi} from 'meteor/janmp:chatterbrain'
 
export createChatBot = ({
  model, system, options = {},
  logCollection
  chatCollection
  botUserData
}) ->
  return unless Meteor.isServer
  model ?= 'gpt-3.5-turbo'
  system ?= "Du bist ein freundlicher, hilfreicher Chatbot"
  openAi = setupOpenAIApi()
  replyMessageId = null

  createMessageStub: ({sessionId}) ->
    replyMessageId = chatCollection.insert
      userId: botUserData.id
      sessionId: sessionId
      text: ''
      chatRole: 'assistant'
      createdAt: new Date()
    replyMessageId

  handleStream: (reply) ->
    text = ''
    done = false
    # we do this the ugly way, because I can't get _.throttle to work
    # with Meteor.bindEnvironment. This problem should disappear with
    # Meteor 3 because of no more fibers.
    interval = Meteor.setInterval ->
      chatCollection.update replyMessageId,
        $set:
          text: text
          createdAt: new Date()
      if done
        Meteor.clearInterval interval
        return
    , 700
    reply?.data?.on 'data', Meteor.bindEnvironment (chunk) ->
      chunk.toString()
      .split '\n'
      .filter (line) -> line.trim() isnt ''
      .forEach (line) ->
        line = line.replace?(/^data: /, '') ? line
        if line is '[DONE]' or typeof line isnt 'string'
          done = true
          return
        response = JSON.parse line
        delta = response?.choices?[0]?.delta?.content ? ''
        text += delta

  call: ({history, logData}) ->
    messages = [
      content: system, role: 'system'
    , history...
    ]
    openAi.createChatCompletion {model, messages, options...}, {responseType: if options?.stream then 'stream'}
    .then (reply) ->
      if options.stream
        reply
      else
        if logCollection and Meteor.isServer
          logCollection.insert {
            model
            messages,
            message: reply?.data?.choices?[0].message
            usage: reply?.data?.usage
            createdAt: new Date()
            logData...
          }
        #return
        message: reply?.data?.choices?[0].message
        usage:
          model: model
          prompt: reply?.data?.usage?.prompt_tokens
          completion: reply?.data?.usage?.completion_tokens
    .catch console.error
  test: -> console.log 'test', {works: true}