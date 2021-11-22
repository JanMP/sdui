import {Meteor} from 'meteor/meteor'

###*
  A wrapper around Meteor.apply to make it thenable
  @type {(options: {method: string, data?: any, options?: Object}) => Promise}
  ###
export meteorApply = ({method, data, options}) -> #returns promise
  new Promise (resolve, reject) ->
    unless method?
      throw new Meteor.Error 'meteorApply: method must be defined'
    params = if data? then [data] else []
    options ?= {}
    Meteor.apply method, params, options, (error, result) ->
      if error then reject(error) else resolve(result)
