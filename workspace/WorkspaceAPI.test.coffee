import {expect} from 'chai'
import {WorkspaceAPI} from './WorkspaceAPI.coffee'
import {Schema} from 'meteor/janmp:sdui'

if Meteor.isServer
  describe 'WorkspaceAPI.partialUpdate', ->

    beforeEach ->
      # Fake underlying source collection
      @sourceCollection = new Mongo.Collection null
      @sourceCollection.remove {}

      # Simple schema
      @formSchema = new Schema
        type: 'object'
        properties:
          title: type: 'string'
          meta:
            type: 'object'
            properties:
              tags:
                type: 'array'
                items: type: 'string'
              views: type: 'number'
          body: type: 'string'

      @workspace = new WorkspaceAPI
        sourceDataOptions:
          sourceName: 'test'
          collection: @sourceCollection
          formSchema: @formSchema
          viewTableRole: 'test-role'
          editRole: 'test-role'
          sdai:
            agentRole: 'agent-role'
        agentRole: 'agent-role'

      @sessionId = 'sess1'

      # create new document
      @workspace.newDocument {sessionId: @sessionId}

    it 'applies simple field patch', ->
      @workspace.updateDocumentFields {sessionId: @sessionId, patch: {title: 'Hello'}}
      doc = @workspace.fetchDocument {sessionId: @sessionId}
      expect(doc.data.title).to.equal 'Hello'

    it 'applies nested patch and unset', ->
      @workspace.updateDocumentFields {sessionId: @sessionId, patch: {meta: {tags: ['a','b'], views: 5}, body: 'Init'}}
      @workspace.updateDocumentFields {sessionId: @sessionId, patch: {meta: {views: 10}, body: null}}
      doc = @workspace.fetchDocument {sessionId: @sessionId}
      expect(doc.data.meta.tags).to.deep.equal ['a','b']
      expect(doc.data.meta.views).to.equal 10
      expect(doc.data).to.not.have.property 'body'
