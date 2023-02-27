import React, {useEffect} from 'react'
import {QueryBlockEditor} from './QueryBlockEditor'
import {SimpleSchema2Bridge as Bridge} from 'uniforms-bridge-simple-schema-2'
import {connectField} from 'uniforms'
import {getNewBlock} from './queryEditorHelpers'
import PartIndex from './PartIndex'
import _ from 'lodash'

import {ActionButton} from '../forms/ActionButton.coffee'

import {DndProvider} from 'react-dnd'
import {HTML5Backend} from 'react-dnd-html5-backend'


export QueryEditor = ({bridge, rule, path, onChange}) ->

  resetRule = -> onChange getNewBlock {bridge, path, type: 'logicBlock'}
  
  path ?= ''

  useEffect ->
    unless rule?
      resetRule()
  , [rule]

  unless rule?
    return null


  <div className="query-editor">
    <div className="header">
      <div>Find documents that satisfy</div>
       <ActionButton
        className="warning"
        onAction={resetRule}
        icon="pi pi-filter-slash"
        label="reset"
      />
    </div>
    <DndProvider backend={HTML5Backend}>
      <QueryBlockEditor
        rule={rule}
        partIndex={new PartIndex()}
        bridge={bridge}
        path={path}
        onChange={onChange}
        isRoot={true}
      />
    </DndProvider>
  </div>

export QueryEditorField = connectField QueryEditor, kind: 'leaf'