export downloadAsFile = ({dataString, mimeType, fileName}) ->
  unless dataString?
    throw new Error 'no dataString given for downloadAsFile'
  mimeType ?= 'text/csv;charset=utf-8'
  fileName ?= 'export.csv'
  element = document.createElement 'a'
  file = new Blob [dataString], type: 'text/csv;charset=utf-8'
  element.href = URL.createObjectURL file
  element.download = fileName
  document.body.appendChild element
  element.click()