import {Meteor} from 'meteor/meteor'
import {ValidatedMethod} from 'meteor/mdg:validated-method'
import {Schema} from 'meteor/janmp:sdui'
import {currentUserMustBeInRole} from '../common/roleChecks.coffee'


export class SdMethod
  ###*
  @param {Object} options - Configuration options for the SdMethod
  @param {String} options.name - The name of the method
  @param {Schema} options.schema - The schema for the method
  @param {String} options.role - The role required to run the method (note: should be 'role', not 'userRole')
  @param {Object} [options.tool] - Optional tool configuration
  @param {String} [options.tool.name] - The name of the tool
  @param {String} options.tool.agentRole - The role required to run the tool
  @param {Function} options.run - The function to run when the method is called
  ###
  constructor: (options) -> # Fixed typo: was "costructor"
    unless (@name = options.name)?
      throw new Meteor.Error 'name is required'
    unless (@schema = options.schema)?
      throw new Meteor.Error 'schema is required'
    unless (@role = options.role)?
      throw new Meteor.Error 'role is required'
    unless (@run = options.run)?
      throw new Meteor.Error 'run is required'
    if options.tool?
      @toolName = options.tool.name ? @name + '.tool'
      unless (@agentRole = options.tool.agentRole)?
        throw new Meteor.Error 'tool.agentRole is required'

    @_method = new ValidatedMethod
      name: @name
      validate: @schema.methodValidator
      run: (args) =>  # Use fat arrow to preserve 'this' context
        console.log "Running method #{@name} with args:", args
        try
          await currentUserMustBeInRole @role
          # Run the method with the validated arguments
          await @run args  # Add await if run returns a promise
        catch error
          throw new Meteor.Error 'Method execution failed', error.message,
            details: error.details  # Include error details if available

    if @toolName?
      @_tool = new ValidatedMethod
        name: @toolName
        validate: @schema.methodValidator
        run: (args) =>
          try
            await currentUserMustBeInRole @agentRole
            # Run the tool with the validated arguments
            await @run args  # Add await if run returns a promise
          catch error
            throw new Meteor.Error 'Tool execution failed', error.message,
              details: error.details  # Include error details if available

  ###*
    @param {Object} args - The arguments to pass to the method
    @returns {Promise} - A promise that resolves when the method is executed
    ###
  call: (args) => @_method.callAsync @name, args




