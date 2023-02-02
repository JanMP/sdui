import {predicateSelectOptions} from './predicates'
import {getConjunctionData} from './conjunctions'
import {getSubjectSelectOptions} from './subjects'
import _ from 'lodash'

export getNewSentence = ({bridge, path}) ->
  type: 'sentence'
  content:
    subject: getSubjectSelectOptions({bridge, path})[0]
    predicate: predicateSelectOptions[0]
    object: value: null

export getNewBlock = ({bridge, path, type, locked = false}) ->
  conjunction = getConjunctionData({bridge, path, type})[0]
  innerContext = if path is '' then conjunction.value else "#{path}.#{conjunction.value}"
  {
    type, locked, conjunction,
    content: _.compact [
      if type is 'contextBlock'
        getNewBlock
          bridge: bridge
          path: innerContext
          type: 'logicBlock'
          locked: true
    ]
  }
