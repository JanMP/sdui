import axios from 'axios'

returnData = (response) ->
  unless response.statusText is 'OK'
    console.error response.statusText
  response.data

handleError = (error) -> console.error error

export createRestClient = (settings) ->
  unless settings?
    console.warn 'janmp:chatterbrain - createRestClient: settings not found'
    return
  {baseUrl, apiKey} = settings
  config = if apiKey?
    headers:
      'api-key': apiKey
  else
    {}
  get: ({path}) ->
    axios.get baseUrl + path, config
    .then returnData
    .catch handleError
  post: ({path, data}) ->
    axios.post baseUrl + path, data, config
    .then returnData
    .catch handleError
  put: ({path, data}) ->
    axios.put baseUrl + path, data, config
    .then returnData
    .catch handleError
  delete: ({path}) ->
    axios.delete baseUrl + path,  config
    .then returnData
    .catch handleError
  head: ({path}) ->
    axios.head baseUrl + path, config
    .then returnData
    .catch handleError

  