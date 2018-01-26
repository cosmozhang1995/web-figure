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
  return minmax(arr)[0]
max = (arr) ->
  return minmax(arr)[1]

arrsort = (arr) ->
  fn = (a, b) ->
    if a > b
      return 1
    else if a < b
      return -1
    else
      return 0
  return arr.sort(fn)

str_repeat = (i, m) -> (i for ii in [1..m]).join('')

sprintf = () ->
  i = 0
  f = arguments[i++]
  s = ''
  o = []
  while f
    if (m = /^[^\x25]+/.exec(f))
      o.push(m[0])
    else if (m = /^\x25{2}/.exec(f))
      o.push('%')
    else if (m = /^\x25(?:(\d+)\$)?(\+)?(0|'[^$])?(-)?(\d+)?(?:\.(\d+))?([b-fosuxX])/.exec(f))
      if (((a = arguments[m[1] || i++]) == null) || (a == undefined))
        throw('Too few arguments.')
      if (/[^s]/.test(m[7]) && (typeof(a) != 'number'))
        throw('Expecting number but found ' + typeof(a))
      switch (m[7])
        when 'b' then a = a.toString(2)
        when 'c' then a = String.fromCharCode(a)
        when 'd' then a = parseInt(a)
        when 'e' then a = (if m[6] then a.toExponential(m[6]) else a.toExponential())
        when 'f' then a = (if m[6] then parseFloat(a).toFixed(m[6]) else parseFloat(a))
        when 'o' then a = a.toString(8)
        when 's' then a = (if ((a = String(a)) && m[6]) then a.substring(0, m[6]) else a)
        when 'u' then a = Math.abs(a)
        when 'x' then a = a.toString(16)
        when 'X' then a = a.toString(16).toUpperCase()
      a = (if (/[def]/.test(m[7]) && m[2] && a >= 0) then ('+' + a) else a)
      c = (if m[3] then (if (m[3] == '0') then '0' else m[3].charAt(1)) else ' ')
      x = m[5] - String(a).length - s.length
      p = (if m[5] then str_repeat(c, x) else '')
      o.push(s + (if m[4] then (a + p) else (p + a)))
    else
      throw('Huh ?!')
    f = f.substring(m[0].length)
  return o.join('')


class SciNumber
  constructor: (bg, idx) ->
    num = bg * Math.pow(10, with_default(idx, 0))
    unit = 1
    index = 0
    # if num < 0.0000000000001 then num = 0
    anum = Math.abs(num)
    if anum > 0
      while anum / unit >= 10
        unit = unit * 10
        index += 1
      while anum / unit < 1
        unit = unit * 0.1
        index -= 1
      anum = Math.floor(anum / unit)
    num = if num > 0 then anum else -anum
    this.num = num
    this.unit = unit
    this.index = index



module.exports.with_default = with_default
module.exports.extend = extend
module.exports.isset = isset
module.exports.parse_matlab_named_arguments = parse_matlab_named_arguments
module.exports.slice = slice
module.exports.minmax = minmax
module.exports.min = min
module.exports.max = max
module.exports.arrsort = arrsort
module.exports.sprintf = sprintf
