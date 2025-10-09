import {expect} from 'chai'
import {Schema} from './Schema.coffee'

if Meteor.isServer
  describe 'Schema required fields handling', ->

    describe 'addProperty', ->
      it 'preserves existing required fields when adding property', ->
        baseSchema = new Schema
          type: 'object'
          properties:
            name: type: 'string'
            email: type: 'string'
          required: ['name']
        
        newSchema = baseSchema.addProperty description: type: 'string'
        
        expect(newSchema._schema.required).to.deep.equal ['name']
        expect(newSchema._schema.properties).to.have.property 'description'
        expect(newSchema._schema.properties).to.have.property 'name'
        expect(newSchema._schema.properties).to.have.property 'email'

      it 'creates empty required array when original schema has none', ->
        baseSchema = new Schema
          type: 'object'
          properties:
            name: type: 'string'
        
        newSchema = baseSchema.addProperty description: type: 'string'
        
        expect(newSchema._schema.required).to.deep.equal []
        expect(newSchema._schema.properties).to.have.property 'description'

    describe 'pick', ->
      it 'filters required array to only include picked keys', ->
        baseSchema = new Schema
          type: 'object'
          properties:
            name: type: 'string'
            email: type: 'string'
            age: type: 'number'
          required: ['name', 'email', 'age']
        
        pickedSchema = baseSchema.pick ['name', 'age']
        
        expect(pickedSchema._schema.required).to.deep.equal ['name', 'age']
        expect(pickedSchema._schema.properties).to.have.property 'name'
        expect(pickedSchema._schema.properties).to.have.property 'age'
        expect(pickedSchema._schema.properties).to.not.have.property 'email'

      it 'handles case when some required fields are not picked', ->
        baseSchema = new Schema
          type: 'object'
          properties:
            name: type: 'string'
            email: type: 'string'
            phone: type: 'string'
          required: ['name', 'email']
        
        pickedSchema = baseSchema.pick ['name', 'phone']
        
        expect(pickedSchema._schema.required).to.deep.equal ['name']
        expect(pickedSchema._schema.properties).to.have.property 'name'
        expect(pickedSchema._schema.properties).to.have.property 'phone'
        expect(pickedSchema._schema.properties).to.not.have.property 'email'

      it 'handles schema without required fields', ->
        baseSchema = new Schema
          type: 'object'
          properties:
            name: type: 'string'
            email: type: 'string'
        
        pickedSchema = baseSchema.pick ['name']
        
        expect(pickedSchema._schema).to.not.have.property 'required'
        expect(pickedSchema._schema.properties).to.have.property 'name'
        expect(pickedSchema._schema.properties).to.not.have.property 'email'

    describe 'omit', ->
      it 'removes omitted keys from required array', ->
        baseSchema = new Schema
          type: 'object'
          properties:
            name: type: 'string'
            email: type: 'string'
            age: type: 'number'
          required: ['name', 'email', 'age']
        
        omittedSchema = baseSchema.omit ['email']
        
        expect(omittedSchema._schema.required).to.deep.equal ['name', 'age']
        expect(omittedSchema._schema.properties).to.have.property 'name'
        expect(omittedSchema._schema.properties).to.have.property 'age'
        expect(omittedSchema._schema.properties).to.not.have.property 'email'

      it 'handles case when omitted key was not required', ->
        baseSchema = new Schema
          type: 'object'
          properties:
            name: type: 'string'
            email: type: 'string'
            phone: type: 'string'
          required: ['name', 'email']
        
        omittedSchema = baseSchema.omit ['phone']
        
        expect(omittedSchema._schema.required).to.deep.equal ['name', 'email']
        expect(omittedSchema._schema.properties).to.have.property 'name'
        expect(omittedSchema._schema.properties).to.have.property 'email'
        expect(omittedSchema._schema.properties).to.not.have.property 'phone'

      it 'handles schema without required fields', ->
        baseSchema = new Schema
          type: 'object'
          properties:
            name: type: 'string'
            email: type: 'string'
        
        omittedSchema = baseSchema.omit ['email']
        
        expect(omittedSchema._schema).to.not.have.property 'required'
        expect(omittedSchema._schema.properties).to.have.property 'name'
        expect(omittedSchema._schema.properties).to.not.have.property 'email'

    describe 'chaining operations', ->
      it 'handles chained pick and addProperty correctly', ->
        baseSchema = new Schema
          type: 'object'
          properties:
            name: type: 'string'
            email: type: 'string'
            age: type: 'number'
          required: ['name', 'email', 'age']
        
        finalSchema = baseSchema.pick(['name', 'age']).addProperty(description: type: 'string')
        
        expect(finalSchema._schema.required).to.deep.equal ['name', 'age']
        expect(finalSchema._schema.properties).to.have.property 'name'
        expect(finalSchema._schema.properties).to.have.property 'age'
        expect(finalSchema._schema.properties).to.have.property 'description'
        expect(finalSchema._schema.properties).to.not.have.property 'email'

      it 'handles chained omit and pick correctly', ->
        baseSchema = new Schema
          type: 'object'
          properties:
            name: type: 'string'
            email: type: 'string'
            age: type: 'number'
            phone: type: 'string'
          required: ['name', 'email', 'age']
        
        finalSchema = baseSchema.omit(['phone']).pick(['name', 'email'])
        
        expect(finalSchema._schema.required).to.deep.equal ['name', 'email']
        expect(finalSchema._schema.properties).to.have.property 'name'
        expect(finalSchema._schema.properties).to.have.property 'email'
        expect(finalSchema._schema.properties).to.not.have.property 'age'
        expect(finalSchema._schema.properties).to.not.have.property 'phone'