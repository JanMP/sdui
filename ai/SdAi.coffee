import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {TextEmbeddingModel} from './TextEmbeddingModel.coffee'
import _ from 'lodash'

export class SdAi
  ###*
    @param {Object} options
    @param {Mongo.Collection} options.collection
    @param {String} options
    @param {Object} options.embeddingModelSettings
    @param {(object) => string} options.getEmbeddingContext
    @param {(object) => object} [options.getFilterFlags]
    ###
  constructor: (options) ->
    @options = options

    @embeddingModel = new TextEmbeddingModel @options.embeddingModelSettings
    unless (@embeddingModel) instanceof TextEmbeddingModel
      throw new Meteor.Error 'embeddingModel is not set'

    @getEmbeddingContext = @options.getEmbeddingContext
    unless typeof @getEmbeddingContext is 'function'
      throw new Meteor.Error 'getEmbeddingContext is not a function'

    @collection = @options.collection
    unless @collection instanceof Mongo.Collection
      throw new Meteor.Error 'collection is not set'

    @getFilterFlags = @options.getFilterFlags

    if Meteor.isServer
      @createIndices()

  createIndices: ->
    try
      collectionExists = (await @collection.findOneAsync())?
      unless collectionExists
        console.log "Collection #{@collection._name} does not exist. Creating collection..."
        await @collection.insertAsync {_id: 'temp', _dummy: true}
        await @collection.removeAsync 'temp'

      existingIndices = await @collection.rawCollection().listSearchIndexes().toArray()
      unless existingIndices.some (index) -> index.name is 'sdaiVectorSearchIndex'
        console.log "Creating vector search index for #{@collection._name}..."
        
        # Get filter flags to include in index
        filterFlags = await @getFilterFlags? {document: null}
        
        # Create fields definition including both vector and filter flags
        fields = [
          type: 'vector'
          path: 'sdai.vector'
          numDimensions: 1024 # TODO: make numDimensions configurable
          similarity: 'cosine'
          quantization: 'none'
        ]
        
        # Add filter flag fields to the index definition
        if filterFlags
          for flag of filterFlags
            fields.push
              type: 'filter'
              path: "sdai.filterFlags.#{flag}"

        index =
          name: 'sdaiVectorSearchIndex'
          type: "vectorSearch"
          definition:
            mappings: dynamic: true
            fields: fields
       
        console.log "Index Definition for #{@collection._name}:", JSON.stringify index, null, 2
        await @collection.rawCollection().createSearchIndex index

    catch error
      console.error "Error creating indices for #{@collection._name}:", error

  embeddingFromContext: ({context}) ->
    @embeddingModel.create {context}

  embeddingFromDocument: ({document}) -> @embeddingFromContext context: @getEmbeddingContext {document}

  updateEmbeddingForDocumentWithSelector: ({selector}) ->
    document = await @collection.findOneAsync selector
    unless document
      throw new Meteor.Error "[updateEmbeddingForDocumentWithId] document with selector #{selector} not found"
    filterFlags = await @getFilterFlags? {document}
    context = await @getEmbeddingContext document: {document..., sdai: {document.sdai..., filterFlags}}
    unless _.isEqual(context, document?.sdai?.context) and _.isEqual(filterFlags, document?.sdai?.filterFlags)
      vector = await @embeddingFromDocument {document}
      @collection.updateAsync document._id,
        $set: sdai: {vector, context, filterFlags}

  updateEmbeddingForDocumentWithId: ({id}) -> @updateEmbeddingForDocumentWithSelector {selector: {_id: id}}

  ###*
    * @param {String[]} flags
    * @return {Object} filterQuery
    ###
  filterQueryfromFlags = (flags = []) ->
    if flags?.length
      $and: flags.map (flag) -> "sdai.filterFlags.#{flag}": $eq: true

  ###*
    * @param {Object} options
    * @param {Number[]} options.vector
    * @param {String[]} [options.filterFlags]
    * @param {Number} [options.limit] - default 10
    * @return {Object[]} documents
    ###
  knnFindDocuments: ({vector, filterFlags, limit = 10}) ->
    @collection.rawCollection().aggregate [
      $vectorSearch:
        index: 'sdaiVectorSearchIndex'
        path: 'sdai.vector'
        queryVector: vector
        numCandidates: limit * 10
        limit: limit
        filter: filterQueryfromFlags filterFlags
    ,
      $addFields:
        score: $meta: 'vectorSearchScore'
    ,
      $unset: 'sdai'
    ]
    .toArray()