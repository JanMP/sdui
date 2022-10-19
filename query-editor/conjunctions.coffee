import _ from 'lodash'


conjunctions =
  $and:
    label: 'satisfy all'
  $or:
    label: 'satisfy at least one'
  $nor:
    label: 'satisfy none'

logicConjunctionSelectOptions =
  _(conjunctions)
  .keys()
  .map (key) ->
    value = conjunctions[key]
    return
      key: key
      value: key
      label: value.label
      context: value.context?.key ? null
  .value()

export getConjunctionData = ({bridge, path, type}) ->
  if type is 'logicBlock'
    return logicConjunctionSelectOptions
  else
    fields = bridge.getSubfields path
    pathWithName = (name) -> if path then "#{path}.#{name}" else name
    return contextConjunctionSelectOptions =
      _(fields)
      .filter (name) ->
        (bridge.getType pathWithName name) in [Array, Object]
      .map (name) ->
        label = bridge.schema._schema[name]?.label ? name
        label = switch type = bridge.getType pathWithName name
          when Array then "for at least one element of sub-document #{label}"
          when Object then "for sub-document #{label}"
          else "Error"
        return
          key: name
          value: name
          context: name
          isArrayContext: type is Array
          label: label
      .value()

export getConjunctionSelectOptions = ({bridge, path, type}) ->
  getConjunctionData({bridge, path, type}).map (conjunction) -> _.pick conjunction, ['key', 'value', 'label']
