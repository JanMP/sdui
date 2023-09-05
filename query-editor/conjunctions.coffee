import _ from 'lodash'





export getConjunctionData = ({bridge, path, type, t}) ->
  
  conjunctions =
    $and:
      label: t?('sdui:allConditions', 'alle Bedingungen (UND)')
    $or:
      label: t?('sdui:anyCondition', 'mindestens eine Bedingung (ODER)')
    $nor:
      label: t?('sdui:noCondition', 'keine Bedingung (NOR)')
  
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
          when Array then "#{t?('sdui:forAtLeastOneOf', 'für mindestens ein Dokument der Liste')} '#{label}'"
          when Object then "#{t?('sdui:forTheDocument', 'für das Dokument')} '#{label}'"
          else "Error"
        return
          key: name
          value: name
          context: name
          isArrayContext: type is Array
          label: label
      .value()

export getConjunctionSelectOptions = ({bridge, path, type, t}) ->
  getConjunctionData({bridge, path, type, t}).map (conjunction) -> _.pick conjunction, ['key', 'value', 'label']
