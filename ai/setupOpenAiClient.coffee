import {Meteor} from 'meteor/meteor'
import {OpenAI} from 'openai'

###*
  Setup OpenAI client with configuration from Meteor settings

  @deprecated This function is deprecated. Use setupChatModel instead.

  Creates an OpenAI client instance with configuration from Meteor settings
  and returns wrapper functions for chat, streaming chat, and embeddings.

  @param {Object} options - Configuration options
  @param {string} [options.settingName='openai'] - Name of the settings key to use for OpenAI configuration
  @returns {Object} Object containing chat, chatStream, and embeddings methods
  @returns {Object} returns.chat - Function for non-streaming chat completions
  @returns {Object} returns.chatStream - Function for streaming chat completions
  @returns {Object} returns.embeddings - Function for creating embeddings
  @throws {Meteor.Error} When OpenAI configuration is missing from settings
  @example
  # Basic usage (deprecated)
  client = setupOpenAiClient()
  response = await client.chat({
    model: 'gpt-4',
    messages: [{role: 'user', content: 'Hello'}]
  })

  # With custom settings key
  client = setupOpenAiClient({settingName: 'customOpenAI'})
  ###
export setupOpenAiClient = ({settingName = 'openai'}) ->
  unless (openAISettings = Meteor.settings?[settingName])?
    throw new Meteor.Error 'no openai configuration in settings json'
  client = new OpenAI openAISettings
  #return
  chat: (props) ->
    client.chat.completions.create {props..., stream: false}
  chatStream: (props) ->
    client.chat.completions.create {props..., stream: true}
  embeddings: (props) ->
    client.embeddings.create props