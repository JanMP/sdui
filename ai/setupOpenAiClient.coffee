import {Meteor} from 'meteor/meteor'
import {OpenAI} from 'openai'

export setupOpenAiClient = ({settingName = 'openai'}) ->
  unless (openAISettings = Meteor.settings[settingName])?
    throw new Meteor.Error 'no openai configuration in settings json'
  client = new OpenAI openAISettings
  #return
  chat: (props) ->
    client.chat.completions.create {props..., stream: false}
  chatStream: (props) ->
    client.chat.completions.create {props..., stream: true}
  embeddings: (props) ->
    client.embeddings.create props