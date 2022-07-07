import _ from 'lodash'


conjunctions =
  $and:
    label: 'alle Bedingungen erfüllt'
  $or:
    label: 'mindestens eine Bedingung erfüllt'
  $nor:
    label: 'keine der Bedingungen erfüllt'

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
          when Array then "für mindestens einen Eintrag im Underdokument #{label}"
          when Object then "für das Unterdokument #{label}"
          else "FEHLER"
        return
          key: name
          value: name
          context: name
          isArrayContext: type is Array
          label: label
      .value()

export getConjunctionSelectOptions = ({bridge, path, type}) ->
  getConjunctionData({bridge, path, type}).map (conjunction) -> _.pick conjunction, ['key', 'value', 'label']
