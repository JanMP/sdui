import {Random} from 'meteor/random'

h = Random.hexString

export generateUUID = ->
  "#{h 8}-#{h 4}-#{h 4}-#{h 4}-#{h 12}"

export isValidUUID = (uuid) ->
  /^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$/.test uuid