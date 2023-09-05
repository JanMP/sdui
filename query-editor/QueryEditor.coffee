import React, {useEffect} from 'react'
import {QueryBlockEditor} from './QueryBlockEditor'
import {SimpleSchema2Bridge as Bridge} from 'uniforms-bridge-simple-schema-2'
import {connectField} from 'uniforms'
import {getNewBlock} from './queryEditorHelpers'
import PartIndex from './PartIndex'
import _ from 'lodash'
import {useTranslation} from 'react-i18next'

import {ActionButton} from '../forms/ActionButton.coffee'

import {DndProvider} from 'react-dnd'
import {HTML5Backend} from 'react-dnd-html5-backend'


export QueryEditor = ({bridge, rule, path, onChange}) ->

  resetRule = -> onChange getNewBlock {bridge, path, type: 'logicBlock'}
  
  path ?= ''

  {t} = useTranslation()

  useEffect ->
    unless rule?
      resetRule()
  , [rule]

  unless rule?
    return null


  <div className="query-editor | overflow-visible">
    <div className="header | flex justify-content-between">
      <div className="pt-3">{t "sdui:findDocuments", "Finde Dokumente, die folgende Bedingungen erfüllen:"}</div>
       <ActionButton
        className="warning | p-button-raised p-button-rounded p-button-text"
        onAction={resetRule}
        icon="pi pi-filter-slash"
        label={t "sdui:reset", "Zurücksetzen "}

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