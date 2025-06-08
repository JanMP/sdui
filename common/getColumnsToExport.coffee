export getColumnsToExport = ({schema}) ->
  schema.firstLevelSchemaKeys
  .filter (key) ->
    # console.log "getColumnsToExport key", key
    options = schema._schema.properties?[key].sdTable ? {}
    if key in ['id', '_id']
      not (options.dontExport ? false) # include ids by default
    else
      not (options.dontExport ? false) # include everything else if not hidden
