import React, {useEffect} from 'react'
import {DynamicField} from '../forms/DynamicField.coffee'
import {SimpleSchema2Bridge as Bridge} from 'uniforms-bridge-simple-schema-2'
# import CodeListenSelect from '../parts/SearchQueryField'
import {ErrorBoundary} from '../common/ErrorBoundary.coffee'

import SimpleSchema from 'simpl-schema'
import Select from 'react-select'
import {getSubjectSelectOptions} from './subjects'
import {predicateSelectOptions} from './predicates'
import PartIndex from './PartIndex'
import _ from 'lodash'

import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faTimes} from '@fortawesome/free-solid-svg-icons'


regexSchema =
  new SimpleSchema
    object:
      type: String

defaultListSchema =
  new SimpleSchema
    object:
      type: String
      uniforms:
        component: -> <span>keine Liste</span>

isList = (predicate) -> predicate in ['$in', '$nin']
isRegex = (predicate) -> predicate is '$regex'
isOther = (predicate) -> not ((isList predicate) or isRegex predicate)

shouldDeleteObject = ({oldPredicate, newPredicate}) ->
  both = (isSomething) -> (isSomething oldPredicate) and isSomething newPredicate
  not ((both isList) or (both isOther) or ((isOther oldPredicate) and isRegex newPredicate))


export QuerySentenceEditor = React.memo ({rule, partIndex, bridge, path, onChange, onRemove}) ->
    
  subjectSelectOptions = getSubjectSelectOptions {bridge, path}
  haveContext = subjectSelectOptions.length > 0
  subjectFitsContext =
    _.some subjectSelectOptions, value: rule.content.subject?.value
  canDisplay = haveContext and subjectFitsContext

  # if we can't display anything usefull we just get ourselves erased
  useEffect ->
    unless canDisplay
      onRemove()
    return
  , [canDisplay]

  pathWithName = (name) -> if path then "#{path}.#{name}" else name

  returnRule = (mutateClone) ->
    clone = _(rule).cloneDeep()
    mutateClone clone
    onChange clone

  # selectOptionsForValue = (d) -> _(d.options).find value: d?.value

  changeSubject = (d) ->
    console.log d
    returnRule (r) ->
      r.content.object.value = null
      r.content.subject = d

  changePredicate = (d) ->
    console.log d
    returnRule (r) ->
      r.content.predicate = d
      if shouldDeleteObject oldPredicate: predicate,  newPredicate: d
        r.content.object.value = null

  changeObject = (d) ->
    returnRule (r) -> r.content.object.value = d

  # set up AutoForm to handle the object field, which depends on
  # both subject and predicate
  subject = rule.content.subject?.value
  object = rule.content.object?.value ? ''
  predicate = rule.content.predicate?.value


  objectSchema = # TODO check if removing the workaround is viable
    if path
      try
        bridge.schema.getObjectSchema(path).pick subject
      catch error
        console.log 'error on calling getObjectSchema'
        bridge.schema.pick subject
    else bridge.schema.pick subject

  switch predicate
    when '$regex'
      objectPath = 'object'
      autoFormSchema = regexSchema
    when '$in', '$nin'
      objectPath = 'object'
      autoFormSchema =
        if (inListField = objectSchema?._schema?[subject]?.QueryEditor?.inListField)?
          new SimpleSchema object: inListField
        else defaultListSchema
    else
      objectPath = subject
      autoFormSchema = objectSchema
  
  autoFormSchemaBridge = new Bridge autoFormSchema
        
  # check if our subject value fits our context
  # and set it to the first select option if it doesn't
  useEffect ->
    if haveContext and not subjectFitsContext
      subjectObject = subjectSelectOptions[0]
      returnRule (r) ->
        r.content.subject = subjectObject
        r.content.object.value = null
    return
  , [subjectFitsContext]

  SentenceForm =
    <ErrorBoundary>
      <div className="flex">
        <div>
          <div className="flex inline">
            <div className="flex-grow">
              <ErrorBoundary>
                <Select
                  className="p-2"
                  value={_.find subjectSelectOptions, value: subject}
                  options={subjectSelectOptions}
                  onChange={changeSubject}
                  name="subject"
                />
              </ErrorBoundary>
            </div>
            <div className="flex-grow">
              <ErrorBoundary>
                <Select
                  className="p-2"
                  value={_.find predicateSelectOptions, value: rule.content.predicate?.value}
                  options={predicateSelectOptions}
                  onChange={changePredicate}
                  name="predicate"
                />
              </ErrorBoundary>
            </div>
          </div>
        </div>
        <div>
          <ErrorBoundary>
            <DynamicField
              className="-m-1"
              schemaBridge={autoFormSchemaBridge}
              fieldName={objectPath}
              label={false}
              value={object}
              onChange={changeObject}
              mayEdit={true}
            />
          </ErrorBoundary>
        </div>
      </div>
    </ErrorBoundary>


  <div className="overflow-visible flex justify-between bg-white rounded mb-2 | query-sentence">
    {if canDisplay then SentenceForm}
    <div className="p-2">
      <button className="icon secondary" onClick={onRemove}>
        <FontAwesomeIcon icon={faTimes}/>
      </button>
    </div>
  </div>
