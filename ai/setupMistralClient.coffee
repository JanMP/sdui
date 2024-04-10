import {Meteor} from 'meteor/meteor'
import MistralClient from '@mistralai/mistralai'

export setupMistralClient = ({settingName = 'mistral'}) ->
  unless (settings = Meteor.settings[settingName])?
    throw new Meteor.Error 'no mistral configuration in settings json'
  unless (apiKey = settings.apiKey)?
    throw new Meteor.Error 'no mistral.apiKey in settings json'
  client = new MistralClient apiKey
  #return
  chat: (props) ->
    console.log 'chat', JSON.stringify props, null, 2
    if props.messages?[1]?.role is 'assistant'
      props.messages.splice(1, 1)
    client.chat {props...}
  chatStream: (props) ->
    console.log 'chatStream', JSON.stringify props, null, 2
    if props.messages?[1]?.role is 'assistant'
      props.messages.splice(1, 1)
    client.chatStream {props...}
  embeddings: (props) ->
    console.log 'embeddings', JSON.stringify props, null, 2
    client.embeddings {props...}