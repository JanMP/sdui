import {Meteor} from 'meteor/meteor'
import {createRestClient} from './RestClient'

qdrantSettings = Meteor.settings.qdrant

qdrant = createRestClient qdrantSettings

# Collections
export createCollection = ({collectionName}) ->
  try
    response = await listCollections()
  catch error
    console.error error
    return
  unless (collectionNames = response?.result?.collections.map ({name}) -> name)?
    console.error 'Could not get collection names'
    return
  if collectionName in collectionNames
    console.log "Collection #{collectionName} already exists."
    return
  qdrant.put
    path: '/collections/' + collectionName
    data:
      vectors:
        size: 1536
        distance: 'Cosine'

export deleteCollection = ({collectionName}) ->
  qdrant.delete
    path: '/collections/' + collectionName

export listCollections = ->
  qdrant.get
    path: '/collections'

export collectionInfo = ({collectionName}) ->
  qdrant.get
    path: '/collections/' + collectionName

# Points
export addPoints = ({collectionName, points}) ->
  qdrant.put
    path: '/collections/' + collectionName + '/points'
    data: {points}

export getPointById = ({collectionName, id}) ->
  qdrant.post
    path: '/collections/' + collectionName + '/points'
    data:
      ids: [id]
      limit: 1
      with_payload: true
      with_vector: true

export removePoints = ({collectionName, points}) ->
  qdrant.post
    path: '/collections/' + collectionName + '/points/delete'
    data: {points}

# Search
export search = ({collectionName, filter, params, vector, limit = 3}) ->
  qdrant.post
    path: '/collections/' + collectionName + '/points/search'
    data: {filter, params, vector, limit, with_payload: true}