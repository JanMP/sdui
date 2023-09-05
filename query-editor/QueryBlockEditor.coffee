import React, {useState, useEffect} from 'react'
import {QuerySentenceEditor} from './QuerySentenceEditor'
import {getConjunctionData, getConjunctionSelectOptions} from './conjunctions'
# import { Button, Icon, Select } from 'semantic-ui-react'
import {Dropdown} from 'primereact/dropdown'
import {Button} from 'primereact/button'
import {getNewSentence, getNewBlock} from './queryEditorHelpers'
import _ from 'lodash'
import PartIndex from './PartIndex'
import {useDrop} from 'react-dnd'
import {useTranslation} from 'react-i18next'


export QueryBlockEditor = React.memo ({rule, partIndex, bridge, path, onChange, onRemove, onAddAfter, isRoot, locked}) ->
  
  {t} = useTranslation()

  isRoot ?= false
  locked ?= isRoot

  onRemove ?= ->
  onAddAfter ?= ->
 
  # data handling
  myContext = rule.conjunction?.context
  isBlock = rule.type in ['contextBlock', 'logicBlock']

  conjunctionData = getConjunctionData {bridge, path, t, type: rule.type}
  conjunctionSelectOptions = getConjunctionSelectOptions {bridge, path, t, type: rule.type}

  cantGetInnerPathType = false

  conjunction = rule?.conjunction?.value ? null

  blockTypeClass =
    switch conjunction
      when '$and' then 'query-block--and | border-orange-400'
      when '$or' then 'query-block--or | border-green-400'
      when '$nor' then 'query-block--nor | border-red-400'
      else
        'query-block--context | border-400'

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
    queryBlockClassName = "query-block | overflow-visible mt-2 pt-2 pl-2 pr-1 border-top-3 border-left-3"
    queryBlockRootClass = 'query-block--root | pr-3'
    className = "#{queryBlockClassName} #{if isRoot then 'query-block--root' else ''} #{blockTypeClass}"
    <div ref={drop} className={className}>
      <div className="header | flex justify-content-between">
        <div className="flex-grow">
          <Dropdown
            value={conjunction}
            options={conjunctionSelectOptions}
            onChange={(e) -> changeConjunction e.value}
            name="conjunction"
          />
        </div>
        <div>
          <Button
            icon="pi pi-filter"
            severity="secondary"
            rounded text
            onClick={addLogicBlock}
            disabled={rule.type is 'contextBlock'}
          />
          <Button
            icon="pi pi-folder"
            severity="secondary"
            rounded text
            onClick={addContextBlock}
            disabled={not childHasContextConjunctionSelectOptions}
          />
          <Button
            icon="pi pi-file"
            severity="secondary"
            rounded text
            onClick={addSentence}
            disabled={(not childWouldHaveSubject) or (rule.type is 'contextBlock')}
          />
          <Button
            icon={if locked then 'pi pi-lock' else 'pi pi-delete-left'}
            severity={if locked then 'secondary' else 'danger'}
            rounded text
            onClick={onRemove}
            disabled={locked}
          />
        </div>
      </div>
      {
        unless children?.length
          <div className="child-container--no-children | p-2 max-w-25rem">
            <span>{t "sdui:requestToAddContentStart", "Benutze die Icons "}</span>
            <i className="pi pi-filter"/>
            <i className="pi pi-folder"/>
            <i className="pi pi-file"/>
            <span>{t "sdui:requestToAddContentEnd", " um Bedingungen hinzuzufügen."}</span>

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
