import React, {useEffect} from 'react'
import {QueryBlockEditor} from './QueryBlockEditor'
import {SimpleSchema2Bridge as Bridge} from 'uniforms-bridge-simple-schema-2'
import {connectField} from 'uniforms'
import {getNewBlock} from './queryEditorHelpers'
import PartIndex from './PartIndex'
import _ from 'lodash'

import {DndProvider} from 'react-dnd'
import {HTML5Backend} from 'react-dnd-html5-backend'


export QueryEditor = ({bridge, rule, path, onChange}) ->

  path ?= ''
  unless rule?
    onChange getNewBlock {bridge, path, type: 'logicBlock'}
    return null

  <div className="overflow-visible query-editor">
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