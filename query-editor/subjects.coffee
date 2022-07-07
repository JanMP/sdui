import _ from 'lodash'

export getSubjectSelectOptions = ({bridge, path}) ->
  fields = bridge.getSubfields path
  pathWithName = (name) -> if path then "#{path}.#{name}" else name
  _(fields)
  .filter (name) ->
    (bridge.getType pathWithName name) not in [Array, Object]
  .map (name) ->
    key: name
    value: name
    label: bridge.getField(pathWithName name).label ? name
  .value()
