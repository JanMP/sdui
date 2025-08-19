import {Meteor} from 'meteor/meteor'
import {SdWorkspaceAPI} from 'meteor/janmp:sdui'

export createWorkspaceAPI = ({
  sourceName, viewRole, editRole, agentRole,
  articleGenerationSchema, tableDataOptions
}) ->
  unless sourceName? or tableDataOptions?
    throw new Error 'sourceName or tableDataOptions is required'
  sourceName ?= "#{tableDataOptions.sourceName}.workspace"
  new SdWorkspaceAPI
    sourceName: sourceName
    collection: new Meteor.Collection sourceName
    articleGenerationSchema: articleGenerationSchema
    viewRole: viewRole
    editRole: editRole
    agentRole: agentRole