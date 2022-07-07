import _ from 'lodash'

#we use the PartIndex to reference the different movin parts in QueryEditor
export default class PartIndex
  constructor: (str) ->
    @str = String(str ? '0')
    @arr = @str.split('.').map (s) -> Number s
    @leaf = @arr[-1..]
    @wood = @arr[...-1]
  addLeaf: (value) ->
    new PartIndex [@arr..., value].join '.'
  setLeaf: (value) ->
    new PartIndex [@wood..., value].join '.'
  inc: -> setLeaf @leaf + 1
  parent: -> new PartIndex @wood.join '.'
  equals: (other) -> @str is other.str
  isDescendantOf: (other) ->
    @str.startsWith other.str
  isAncestorOf: (other) ->
    other.str.startsWith @str
  partOf: (rule) ->
    getPart = (part, arr) ->
      myArr = [arr...]
      if myArr.length > 0 and part.type is 'block'
        index = myArr.shift()
        getPart part.content[index], myArr
      else
        part
    getPart rule, @arr[1..]
