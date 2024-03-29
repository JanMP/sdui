import {Meteor} from 'meteor/meteor'
import {Roles} from 'meteor/alanning:roles'
import {useTracker} from 'meteor/react-meteor-data'


###*
  @typedef {import("../interfaces").Role} Role
  ###

###*
  For use in subscriptions, where Meteor.userId is unavailable.
  
  Think about the trustworthiness of the UserId before using this!
  
  In addition to roles defined via alanning:roles you can specify
  'any' and 'logged-in'

  @param {{role: Role, id: string}} params
  @return {boolean}
  ###
export userWithIdIsInRole = ({role, id}) ->
  switch
    when role is 'any'
      true
    when role is 'logged-in'
      id?
    when typeof role is 'function'
      role?(id) ? false
    when role?.role?
      if role.forAnyScope
        (scopesForCurrentUserInRole role.role)?.length > 0
      else
        Roles.userIsInRole id, role.role, role.scope
    else
      Roles.userIsInRole id, role

###*
  In addition to roles defined via alanning:roles you can specify
  'any' and 'logged-in'
  @param {Role} role
  @return {boolean}
  ###
export currentUserIsInRole = (role) -> userWithIdIsInRole id: Meteor.userId(), role: role

###*
  React hook, using useTracer.
  In addition to roles defined via alanning:roles you can specify
  'any' and 'logged-in'
  @param {Role} role
  @return {boolean}
  ###
export useCurrentUserIsInRole = (role) -> useTracker -> currentUserIsInRole role

###*
  Use this in Meteor Methods.

  In addition to roles defined via alanning:roles you can specify
  'any' and 'logged-in'
  @param {Role} role - the alanning:role 
  @throws {Meteor.Error} throws an error when user is not in role
  ###
export currentUserMustBeInRole = (role) ->
  unless currentUserIsInRole role
    throw new Meteor.Error "user must be in role #{role}"

###*
  @param {string | Array<string>} role
  @return {Array}
  ###
export scopesForCurrentUserInRole = (role) ->
  Roles.getScopesForUser Meteor.userId(), role

###*
  @param {string | Array<string>} role
  @return {Array}
  ###
export useScopesForCurrentUserInRole = (role) -> useTracker -> scopesForCurrentUserInRole role