import {expect} from 'chai'
import {TextEmbeddingModel} from '../ai/TextEmbeddingModel'
import sinon from 'sinon'

# TODO Figure out how to do these tests, this does not work yet
# Claude has trouble getting this right, so we will skip it for now

if Meteor.isServer
  describe 'TextEmbeddingModel', ->
    beforeEach ->
      # Create a proper stub for fetch that returns a Promise
      @fetchStub = sinon.stub()
      global.fetch = @fetchStub

      # Sample settings
      @settings =
        apiKey: 'test-api-key'
        model: 'voyage-01'
        vendor: 'voyage'

      # Create new instance for each test
      @model = new TextEmbeddingModel(@settings)

      # Sample embedding response
      @sampleEmbedding = [0.1, 0.2, 0.3]
      @mockResponse =
        data: [
          embedding: @sampleEmbedding
        ]

  describe 'constructor', ->
    it 'should create instance with correct settings', ->
        model = new TextEmbeddingModel(@settings)
        expect(model.settings).to.deep.equal(@settings)
        expect(model).to.be.instanceOf(TextEmbeddingModel)

  describe 'create', ->
    it 'should call Voyage API with correct parameters', (done) ->
      @fetchStub.returns(Promise.resolve({
        ok: true
        json: => Promise.resolve(@mockResponse)
      }))

      context = 'test context'

      @model.create({ context })
      .then =>
          expect(@fetchStub.calledOnce).to.be.true

        callArgs = @fetchStub.firstCall.args
        expect(callArgs[0]).to.equal('https://api.voyageai.com/v1/embeddings')
        expect(callArgs[1]).to.deep.include
          method: 'POST'
          headers:
            'Content-Type': 'application/json'
            'Authorization': "Bearer #{@settings.apiKey}"

        requestBody = JSON.parse(callArgs[1].body)
        expect(requestBody).to.deep.equal
          model: @settings.model
          input: context
        done()
      .catch(done)

    it 'should return embedding array on successful response', (done) ->
      @fetchStub.returns(Promise.resolve({
        ok: true
        json: => Promise.resolve(@mockResponse)
      }))

      @model.create({ context: 'test' })
      .then (result) =>
        expect(result).to.deep.equal(@sampleEmbedding)
        done()
      .catch(done)

    it 'should throw Meteor.Error on API error response', (done) ->
      @fetchStub.returns(Promise.resolve({
        ok: false
        statusText: 'Bad Request'
      }))

      @model.create({ context: 'test' })
      .then ->
        done(new Error('Should have thrown an error'))
      .catch (error) ->
        expect(error.message).to.equal('Error fetching embedding from Voyage: Bad Request')
        expect(error).to.be.instanceOf(Meteor.Error)
        done()

    it 'should throw error on network failure', (done) ->
      @fetchStub.returns(Promise.reject(new Error('Network error')))

      @model.create({ context: 'test' })
      .then ->
        done(new Error('Should have thrown an error'))
      .catch (error) ->
        expect(error.message).to.equal('Network error')
        done()
