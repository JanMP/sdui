{floor, log10, round} = Math

export default (n, options) ->
  options ?= {}
  {onlyFromE3 = false} = options
  
  return "0" if n is 0
  e = floor log10 n
  e3 = if (-3 < e < 3) and not onlyFromE3 then e else e - e %% 3
  prefix = switch e3
    when 12 then ' T'
    when 9 then 'G'
    when 6 then 'M'
    when 3 then 'k'
    when 2 then 'h'
    when 1 then 'da'
    when 0 then ''
    when -1 then 'd'
    when -2 then 'c'
    when -3 then 'm'
    when -6 then 'μ'
    when -9 then 'n'
    when -12 then 'p'
    else "e#{e3}"
  
  "#{round((n * 10 ** -e3) * 100) / 100}#{prefix}"