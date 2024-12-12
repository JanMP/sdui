import {Meteor} from 'meteor/meteor'

getTextEmbeddingVoyage = ({context, settings}) ->
  fetch 'https://api.voyageai.com/v1/embeddings',
    method: 'POST'
    headers:
      'Content-Type': 'application/json'
      'Authorization': "Bearer #{settings.apiKey}"
    body: JSON.stringify
      model: settings.model
      input: context
  .then (response) ->
    if response.ok
      response.json()
    else
      throw new Meteor.Error "Error fetching embedding from Voyage: #{response.statusText}"
  .then (data) ->
    data.data[0].embedding


export class TextEmbeddingModel
  ###*
    * @param {object} settings - The settings for the model.
    * @prop {string} settings.apiKey - The API key for the model.
    * @prop {string} settings.model - The model to use.
    * @prop {string} settings.vendor - should be 'voyage' for now.
    ###
  constructor: (settings) ->
    @settings = settings
  
  create: ({context}) -> getTextEmbeddingVoyage {@settings, context}
  

