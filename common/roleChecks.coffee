import {Meteor} from 'meteor/meteor'
import {Roles} from 'meteor/alanning:roles'
import {useTracker} from 'meteor/react-meteor-data'

###*
  For use in subscriptions, where Meteor.userId is unavailable.
  
  Think about the trustworthiness of the UserId before using this!
  
  In addition to roles defined via alanning:roles you can specify
  'any', 'logged-in' and 'username-is-admin'

  @param {{role: string, id: string}}
  @return {boolean}
  ###
export userWithIdIsInRole = ({role, id}) ->
  switch role
    when 'any'
      true
    when 'logged-in'
      id?
    when 'username-is-admin'
      Meteor.user()?.username is 'admin'
    else
      Roles.userIsInRole id, role

###*
  In addition to roles defined via alanning:roles you can specify
  'any', 'logged-in' and 'username-is-admin'
  @param {string} role
  @return {boolean}
  ###
export currentUserIsInRole = (role) -> userWithIdIsInRole id: Meteor.userId(), role: role

###*
  React hook, using useTracer.
  In addition to roles defined via alanning:roles you can specify
  'any', 'logged-in' and 'username-is-admin'
  @param {string} role
  @return {boolean}
  ###
export useCurrentUserIsInRole = (role) -> useTracker -> currentUserIsInRole role

###*
  Use this in Meteor Methods.

  In addition to roles defined via alanning:roles you can specify
  'any', 'logged-in' and 'username-is-admin'
  @param {string} role - the alanning:role 
  @throws {Meteor.Error} throws an error when user is not in role
  ###
export currentUserMustBeInRole = (role) ->
  unless currentUserIsInRole role
    throw new Meteor.Error "user must be in role #{role}"