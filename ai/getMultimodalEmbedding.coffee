import {Meteor} from 'meteor/meteor'

export getMultimodalEmbedding = ({content, settings}) ->
  unless Meteor.isServer
    throw new Error "getMultimodalEmbedding can only be called on the server"
  fetch 'https://api.voyageai.com/v1/multimodalembeddings',
    method: 'POST'
    headers:
      'Content-Type': 'application/json'
      'Authorization': "Bearer #{settings.apiKey}"
    body: JSON.stringify
      inputs: [{content}]
      model: settings.model
  .then (response) ->
    if response.ok
      return response.json()
    else
      throw new Error "Failed to fetch multimodal embeddings: #{response.statusText}"
  .then (response) ->
    response.data[0].embedding
  # .catch (error) ->
  #   throw new Meteor.Error error.error, error.message