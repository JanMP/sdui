export getColumnsToExport = ({schema}) ->
  schema._firstLevelSchemaKeys
  .filter (key) ->
    options = schema._schema[key].sdTable ? {}
    if key in ['id', '_id']
      not (options.dontExport ? true) # don't include ids by default
    else
      not (options.dontExport ? false) # include everything else if not hidden
  