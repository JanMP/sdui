import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {TextEmbeddingModel} from './TextEmbeddingModel.coffee'

export class SdAi
  ###*
    # @param {Object} options
    # @param {Object} options.embeddingModelSettings
    # @param {Mongo.Collection} options.collection
    # @param {(object) => string} options.getEmbeddingContext
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

  embeddingFromContext: ({context}) ->
    @embeddingModel.create {context}

  embeddingFromDocument: ({document}) -> @embeddingFromContext context: @getEmbeddingContext {document}

  updateEmbeddingForDocumentWithId: ({id}) ->
    document = await @collection.findOneAsync {_id: id}
    unless document
      throw new Meteor.Error "[updateEmbeddingForDocumentWithId] document with id #{id} not found"
    context = @getEmbeddingContext {document}
    if context isnt document?.sdai?.context
      vector = await @embeddingFromDocument {document}
      @collection.updateAsync id,
        $set: sdai: {vector, context}

  knnFindDocuments: ({vector, limit = 10}) ->
    @collection.rawCollection().aggregate [
      $vectorSearch:
        queryVector: vector
        path: 'sdai.vector'
        numCandidates: limit * 10
        limit: limit
        index: 'sdaiVectorSearchIndex'
    ,
      $addFields:
        score: $meta: 'vectorSearchScore'
    ,
      $unset: 'sdai'
    ]
    .toArray()

  
 