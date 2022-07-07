import {predicateSelectOptions} from './predicates'
import {getConjunctionData} from './conjunctions'
import {getSubjectSelectOptions} from './subjects'

export getNewSentence = ({bridge, path}) ->
  type: 'sentence'
  content:
    subject: getSubjectSelectOptions({bridge, path})[0]
    predicate: predicateSelectOptions[0]
    object: value: null

export getNewBlock = ({bridge, path, type}) ->
  type: type
  conjunction: getConjunctionData({bridge, path, type})[0]
  content: []
