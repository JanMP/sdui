import React, {useState, useEffect} from 'react'
import {QuerySentenceEditor} from './QuerySentenceEditor'
import { getConjunctionData, getConjunctionSelectOptions } from './conjunctions'
# import { Button, Icon, Select } from 'semantic-ui-react'
import {Dropdown} from 'primereact/dropdown'
import {getNewSentence, getNewBlock} from './queryEditorHelpers'
import _ from 'lodash'
import PartIndex from './PartIndex'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faFilter} from '@fortawesome/free-solid-svg-icons/faFilter'
import {faFolder} from '@fortawesome/free-solid-svg-icons/faFolder'
import {faFile} from '@fortawesome/free-solid-svg-icons/faFile'
import {faTimes} from '@fortawesome/free-solid-svg-icons/faTimes'
import {faLock} from '@fortawesome/free-solid-svg-icons/faLock'
import {useDrop} from 'react-dnd'


export QueryBlockEditor = React.memo ({rule, partIndex, bridge, path, onChange, onRemove, onAddAfter, isRoot, locked}) ->
  
  isRoot ?= false
  locked ?= isRoot

  onRemove ?= ->
  onAddAfter ?= ->
 
  # data handling
  myContext = rule.conjunction?.context
  isBlock = rule.type in ['contextBlock', 'logicBlock']

  conjunctionData = getConjunctionData {bridge, path, type: rule.type}
  conjunctionSelectOptions = getConjunctionSelectOptions {bridge, path, type: rule.type}

  cantGetInnerPathType = false

  conjunction = rule?.conjunction?.value ? null

  blockTypeClass =
    switch conjunction
      when '$and' then 'query-block--and'
      when '$or' then 'query-block--or'
      when '$nor' then 'query-block--nor'
      else
        'query-block--context'

  [{canDrop, isOver}, drop] = useDrop ->
    accept: 'fnord'
    drop: (item, monitor) ->
      unless monitor.didDrop()
        console.log 'drop', {item}
        addPart item
    collect: (monitor) ->
      isOver: monitor.isOver()
      canDrop: monitor.canDrop()

  innerPath = switch
    when myContext? and path then "#{path}.#{myContext}"
    when myContext? then myContext
    else path

  # if we can't get a type for innerPath that means there is something wrong with this branch of the rule
  # (most likely because the subdocument was changed above) so we just saw this branch off
  try
    if path and (bridge.getType innerPath) is Array
      innerPath = "#{innerPath}.$"
  catch
    cantGetInnerPathType = true

  useEffect ->
    if cantGetInnerPathType
      console.log 'cantGetInnerPathType', rule
      onRemove()
      return
  , [cantGetInnerPathType]

  childHasContextConjunctionSelectOptions =
    getConjunctionData({bridge, path: innerPath, type: 'contextBlock'}).length > 0

  childWouldHaveSubject = getNewSentence({bridge, path: innerPath}).content.subject?
 
  returnRule = (mutateClone) ->
    clone = _(rule).cloneDeep()
    mutateClone clone
    onChange _(clone).cloneDeep() #CHECK if we can do with cloning only once

  selectValueObject = (d) ->
    _(conjunctionData).find value: d

  changeConjunction = (d) -> returnRule (r) -> r.conjunction = selectValueObject d

  changePart = (index) -> (d) -> returnRule (r) -> r.content[index] = d

  removePart = (index) -> -> returnRule (r) -> r.content.splice index, 1

  addLogicBlock = -> returnRule (r) -> r.content.push getNewBlock {bridge, path: innerPath, type: 'logicBlock'}

  addContextBlock = -> returnRule (r) -> r.content.push getNewBlock {bridge, path: innerPath, type: 'contextBlock'}

  addSentence = -> returnRule (r) -> r.content.push getNewSentence {bridge, path: innerPath}

  addPart = (d) ->
    console.log "addRule", d
    returnRule (r) -> r.content.push d

  addPartAfter = (index) -> (d) -> returnRule (r) -> r.content.splice index, 0, d


  atTop =
    isBlock and rule.content.length > 0

  mainStyle = {}
  showTop = false
  showBottom = false

  if isBlock
    children = rule.content.map (part, index) ->
      <div key={index}>
        <QueryBlockEditor
          rule={part}
          partIndex={partIndex.addLeaf index}
          bridge={bridge}
          path={innerPath}
          onChange={changePart index}
          onRemove={removePart index}
          onAddAfter={addPartAfter index}
          locked={part.locked}
        />
      </div>


  if isBlock
    <div ref={drop} className="query-block #{if isRoot then 'query-block--root' else ''} #{blockTypeClass}">
      <div className="header">
        <div className="flex-grow">
          <Dropdown
            value={conjunction}
            options={conjunctionSelectOptions}
            onChange={(e) -> changeConjunction e.value}
            name="conjunction"
          />
        </div>
        <div>
          <button
            className="icon secondary"
            onClick={addLogicBlock}
            disabled={rule.type is 'contextBlock'}
          >
            <FontAwesomeIcon icon={faFilter}/>
          </button>
          <button
            className="icon secondary"
            onClick={addContextBlock}
            disabled={not childHasContextConjunctionSelectOptions}
          >
            <FontAwesomeIcon icon={faFolder}/>
          </button>
          <button
            className="icon secondary"
            onClick={addSentence}
            disabled={(not childWouldHaveSubject) or (rule.type is 'contextBlock')}
          >
            <FontAwesomeIcon icon={faFile}/>
          </button>
          {
            if locked
              <button
                className="icon secondary"
                disabled
              >
                <FontAwesomeIcon icon={faLock}/>
              </button>
            else
              <button
                className="icon secondary"
                onClick={onRemove}
              >
                <FontAwesomeIcon icon={faTimes}/>
              </button>
          }
        </div>
      </div>
      {
        unless children?.length
          <div className="child-container--no-children">
            <span>Please add Conditions for Data Fields </span>
            <FontAwesomeIcon icon={faFile}/>
            <span>, Embedded Data Fields from related Data Sets </span>
            <FontAwesomeIcon icon={faFolder}/>
            <span> or combinations of Conditions </span>
            <FontAwesomeIcon icon={faFilter}/>
          </div>
      }
      <div className="child-container">{children}</div>
    </div>
  else if rule.type is 'sentence'
    <QuerySentenceEditor
      rule={rule}
      partIndex={partIndex}
      bridge={bridge}
      path={innerPath}
      onChange={onChange}
      onRemove={onRemove}
      onAddAfter={onAddAfter}
    />
