with_default = (item, default_val) ->
  if item == undefined || item == null
    return default_val
  else
    return item

extend = () ->
  first = arguments[0]
  for obj in slice(arguments, 1)
    if typeof obj == "object"
      for k, v of obj
        first[k] = v
  return first

isset = (val) -> (val == null || val == undefined)

parse_matlab_named_arguments = (args) ->
  name = undefined
  dict = {}
  for item in args
    if typeof name == "string"
      dict[name] = item
      name = undefined
      continue
    name = item
  return dict

slice = (arrlike, left, right) ->
  if left == undefined
    left = 0
  if right == undefined
    right = arrlike.length
  return (arrlike[i] for i in [left..right])

minmax = (arr) ->
  minval = arr[0]
  maxval = arr[0]
  for val in arr
    if minval > val
      minval = val
    if maxval < val
      maxval = val
  return [minval, maxval]
min = (arr) ->
  return minval(arr)[0]
max = (arr) ->
  return minval(arr)[1]

module.exports.with_default = with_default
module.exports.extend = extend
module.exports.isset = isset
module.exports.parse_matlab_named_arguments = parse_matlab_named_arguments
module.exports.slice = slice
module.exports.minmax = minmax
module.exports.min = min
module.exports.max = max
