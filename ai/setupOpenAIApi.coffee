import {Meteor} from 'meteor/meteor'
import {OpenAI} from 'openai'

export setupOpenAIApi = ->
  unless (openAISettings = Meteor.settings.openai)?
    throw new Meteor.Error 'no openai configuration in settings json'
  new OpenAI openAISettings
