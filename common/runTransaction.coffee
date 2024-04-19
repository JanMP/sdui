import {Meteor} from 'meteor/meteor'
import {MongoInternals} from 'meteor/mongo'

export runTransaction = (fn) ->
  {client} = MongoInternals.defaultRemoteCollectionDriver().mongo
  session = client.startSession()
  session.startTransaction()
  try
    result = await fn session
    await session.commitTransaction()
    result
  catch error
    await session.abortTransaction()
    console.error error.message
    throw new Meteor.Error 'transaction-failed', error.message
  finally
    session.endSession()