import {
  createCollection, deleteCollection, listCollections, collectionInfo,
  addPoints, getPointById, removePoints, search
} from './qdrant'


export default ({collectionName}) ->
  createCollection {collectionName}

  drop: -> deleteCollection {collectionName}
  recreate: ->
    deleteCollection {collectionName}
    .then ->
      createCollection {collectionName}
  listCollections: listCollections
  info: -> collectionInfo({collectionName})
  addPoints: ({points}) -> addPoints({collectionName, points})
  getPointById: ({id}) -> getPointById({collectionName, id})
  removePoints: ({points}) -> removePoints({collectionName, points})
  search:
    ({filter, params, vector, limit = 3}) ->
      search({collectionName, filter, params, vector, limit})