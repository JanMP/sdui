# import { Session } from 'meteor/session'
import {useTracker} from 'meteor/react-meteor-data'

export useSession = (key, intitialValue) ->
  Session.setDefault key, intitialValue
  value = useTracker -> Session.get key
  setValue = (newValue) -> Session.set key, newValue
  [value, setValue]