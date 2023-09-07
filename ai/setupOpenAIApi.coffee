import {Configuration, OpenAIApi} from 'openai'

export setupOpenAIApi = ->
  unless (openaiSettings = Meteor.settings.openai)?
    throw new Meteor.Error 'no openai configuration in settings json'
  configuration = new Configuration openaiSettings
  new OpenAIApi configuration
