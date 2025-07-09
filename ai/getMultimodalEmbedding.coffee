import {Meteor} from 'meteor/meteor'

###*
  Fetches multimodal embeddings from the Voyage AI API

  We don't use this anywhere and it's not tested.

  This function takes content (which can include text, images, or other multimodal data)
  and returns a vector embedding representation using Voyage AI's multimodal embedding model.
  The function is server-side only and requires valid API credentials.

  @param {Object} options - The configuration object
  @param {*} options.content - The content to embed (can be text, image, or multimodal data)
  @param {Object} options.settings - API configuration settings
  @param {string} options.settings.apiKey - The Voyage AI API key for authentication
  @param {string} options.settings.model - The embedding model to use (e.g., 'voyage-multimodal-3')
  @returns {Promise<number[]>} A promise that resolves to an array of numbers representing the embedding vector
  @throws {Error} Throws an error if called on the client side
  @throws {Error} Throws an error if the API request fails
  @example
  # Get embedding for text content
  embedding = await getMultimodalEmbedding({
    content: "This is a sample text"
    settings: {
      apiKey: "your-api-key"
      model: "voyage-multimodal-3"
    }
  })
  #
  # Get embedding for multimodal content
  embedding = await getMultimodalEmbedding({
    content: {
      type: "image_url"
      image_url: "https://example.com/image.jpg"
    }
    settings: {
      apiKey: "your-api-key"
      model: "voyage-multimodal-3"
    }
  })
  ###
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