import {Meteor} from 'meteor/meteor'

getTextEmbeddingVoyage = (text, settings) ->
  fetch 'https://api.voyageai.com/v1/embeddings',
    method: 'POST'
    headers:
      'Content-Type': 'application/json'
      'Authorization': "Bearer #{settings.apiKey}"
    body: JSON.stringify
      model: settings.model
      input: text
  .then (response) ->
    if response.ok
      response.json()
    else
      throw new Meteor.Error "Error fetching embedding from Voyage: #{response.statusText}"
  .then (data) ->
    data.data[0].embedding

export getTextEmbedding = ({text, settings}) ->
  unless settings?
    throw new Meteor.Error "no settings for Embedding model given"
  switch settings.vendor
    when 'voyage' then getTextEmbeddingVoyage text, settings
    else
      throw new Meteor.Error "unknown vendor for Embedding model: #{settings.vendor}"