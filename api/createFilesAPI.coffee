import {Meteor} from 'meteor/meteor'
import SimpleSchema from 'simpl-schema'
import {ValidatedMethod} from 'meteor/mdg:validated-method'
import {S3, ListObjectsCommand, PutObjectCommand} from '@aws-sdk/client-s3'
import {getSignedUrl} from '@aws-sdk/s3-request-presigner'
import {currentUserMustBeInRole} from '../common/roleChecks.coffee'

export createFilesAPI = ({sourceName, collection, uploadUserRole, uploadPublicRole, getFileListRole}) ->

  unless sourceName?
    throw new Error 'no sourceName given'

  unless collection?
    throw new Error 'no collection given'

  unless uploadUserRole?
    uploadUserRole = 'username-is-admin'
    console.warn "[createFilesAPI #{sourceName}]:
      no uploadUserRole defined, using username-is-admin"

  unless uploadPublicRole?
    uploadPublicRole = 'username-is-admin'
    console.warn "[createFilesAPI #{sourceName}]:
      no uploadPublicRole defined, using username-is-admin"

  unless getFileListRole?
    getFileListRole = 'username-is-admin'
    console.warn "[createFilesAPI #{sourceName}]:
      no getFileListRole defined, using username-is-admin"

  if Meteor.isServer
    unless (s = Meteor.settings[sourceName])?
      throw new Error "Meteor.settings: missing key #{sourceName}"
    
    bucket = s.bucket

    s3Client =
      new S3
        endpoint: s.endpoint
        region: s.region
        credentials:
          accessKeyId: s.accessKeyId
          secretAccessKey: s.secretAccessKey


    getFileList = ({prefix}) ->
      s3Client
        .send new ListObjectsCommand
          Bucket: bucket
          Prefix: prefix
        .then (data) ->
          data.Contents?.map (c) ->
            key: c.Key
            size: c.Size
            prefix: c.Prefix


    getUploadUrl = ({name, size, type}) ->
      getSignedUrl s3Client,
        new PutObjectCommand
          Bucket: bucket
          Key: name
          ContentType: type
      ,
        expiresIn: 15 * 60

  new ValidatedMethod
    name: "#{sourceName}.getFileList"
    validate:
      new SimpleSchema
        select:
          type: String
          allowedValues: ['publicOnly', 'userOnly']
          optional: true
      .validator()
    run: ({select}) ->
      currentUserMustBeInRole getFileListRole
      if Meteor.isServer
        privateList = []
        publicList = []|
        unless select is 'publicOnly'
          privateList = await getFileList prefix: "#{Meteor.userId()}/"
        
  new ValidatedMethod
    name: "#{sourceName}.getUploadUrl"
    validate:
      new SimpleSchema
        name: String
        size: Number
        type: String
        public:
          type: Boolean
          optional: true
      .validator()
    run: (params) ->
      if Meteor.isServer
        await getUploadUrl params

