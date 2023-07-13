escapeRegEx = (string) -> string.replace /[-\/\\^$*+?.()|[\]{}]/g, '\\$&'
regExRegEx = /^\/(.*)\/([gimsuy]*)$/ # get body and flags

export default (inputString) ->
  regExRegEx
  [regExBody, flags] = (inputString.match regExRegEx)?[1..2] ? [null,null]
  regExBodyIsValid =
    try
      new RegExp regExBody
      true
    catch error
      false

  [processedString, isValidRegEx, warn] =
    switch
      when regExBody? and regExBodyIsValid
        [regExBody, true, false] #looks like a regex and is fine
      when regExBody?
        [(escapeRegEx regExBody), false, true] #looks like it should be a valid regex, but isn't
      else
        [(escapeRegEx inputString), false, false]

  {isValidRegEx, warn, flags, processedString}

