export downloadAsFile = ({dataString, mimeType, fileName}) ->
  unless dataString?
    throw new Error 'no dataString given for downloadAsFile'
  
  # Set appropriate defaults based on file extension
  if not mimeType?
    if fileName?.endsWith('.json')
      mimeType = 'application/json;charset=utf-8'
    else
      mimeType = 'text/csv;charset=utf-8'
  
  fileName ?= if mimeType.includes('json') then 'export.json' else 'export.csv'
  
  element = document.createElement 'a'
  file = new Blob [dataString], type: mimeType
  element.href = URL.createObjectURL file
  element.download = fileName
  document.body.appendChild element
  element.click()
  document.body.removeChild element  # Cleanup
