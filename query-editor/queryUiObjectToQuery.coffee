import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
# import {CodeListen} from '/imports/api/CodeListen'

export default ({queryUiObject, getList}) ->

  getList ?= ({subject, predicate, object}) -> []

  traverseTree = (obj, context = '') ->
    dot = if context is '' then '' else '.'
    return {} unless obj?
    switch obj.type
      when'logicBlock'
        unless obj.content.length > 0
          throw new Meteor.Error 'and-or-nor-empty', 'Block mit logischen Verknüpfungen darf nicht leer sein.'
        "#{obj.conjunction.value}": obj.content.map (childObj) -> traverseTree childObj, context
      when 'contextBlock'
        newContext = "#{context}#{dot}#{obj.conjunction.value}"
        if obj.conjunction.isArrayContext
          "#{newContext}":
            $elemMatch:
              traverseTree obj.content[0]
        else
          traverseTree obj.content[0], newContext
      when 'sentence'
        subject = "#{context}#{dot}#{obj.content.subject?.value}"
        predicate = "#{obj.content.predicate?.value}"
        object = obj.content.object
        unless subject? and predicate? and object?
          throw new Meteor.Error 'missing-sentence-part', 'Ein Satzteil fehlt.'
        if predicate in ['$in', '$nin']
          id = obj.content.object.value
          object.value = getList {subject, predicate, object} #CodeListen.findOne(new Mongo.ObjectID id)?.regexs or []
        result =
          "#{subject}":
            "#{predicate}": object.value
        if predicate is '$regex'
          unless object.value? and (try (new RegExp object.value)?)
           result = {}
        if predicate is '$regex' and obj.content.ignoreCase then result[subject]['$options'] = 'i'
        result
      else
        throw new Meteor.Error 'invalid-object-type'

  unless queryUiObject?
    throw new Meteor.Error 'missing-queryUiObject'
  unless queryUiObject.content?
    throw new Meteor.Error 'missing-queryUiObject-content'
  
  try
    traverseTree queryUiObject
  catch error
    console.error error
    return error