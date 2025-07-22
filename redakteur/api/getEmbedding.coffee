import {Meteor} from 'meteor/meteor'
import {setupOpenAiClient} from 'meteor/janmp:sdui'

if Meteor.isServer
  client = setupOpenAiClient settingName: 'openaiFM'

export getEmbedding = ({text}) ->
  return unless Meteor.isServer
  embeddingModel = Meteor.settings.embeddingModel ? 'text-embedding-ada-002'
  client.embeddings
    model: embeddingModel
    input: text
  .then (result) ->
    result.data[0].embedding
  .catch (error) ->
    throw new Meteor.Error error.error, error.message

