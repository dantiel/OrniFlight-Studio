###
# Æther — Functional utility belt for OrniFlight Studio
# Adapted from essential.js (Cedric Ruiz, MIT)
# CoffeeScript idioms for hermetic React composition
###

# ── Core ─────────────────────────────────────
_ = {}
id = (x) -> x
K = (x) -> -> x
builtin = id.bind.bind id.call
toArray = builtin Array::slice
variadic = (as...) -> as

# ── Currying ─────────────────────────────────
ncurry = (n, f, as=[]) -> (bs...) ->
  bs = as.concat bs
  if bs.length < n then ncurry n, f, bs else f bs...

curry = (f) -> (as...) ->
  if f.length > as.length then ncurry f.length, f, as else f as...

apply = curry (f, as) -> f as...

partial = (f, as...) -> (bs...) ->
  args = as.concat bs
  i = args.length
  while i--
    if args[i] is _
      args[i] = args.splice(-1)[0]
  f args...

# ── Composition ──────────────────────────────
compose = (fs...) -> fs.reduce (f, g) -> (as...) -> f g as...
sequence = (fs...) -> (xs) -> xs.map (x, i) -> fs[i]? x
pipe = (fs...) -> fs.reduceRight (f, g) -> (as...) -> g f as...

# ── Collection ops (data-first) ──────────────
fold = curry (acc, f, xs) -> xs.reduce f, acc
map = curry (f, xs) -> xs.map f
filter = curry (f, xs) -> xs.filter f
each = curry (f, xs) -> xs.forEach f
any = curry (f, xs) -> xs.some f
all = curry (f, xs) -> xs.every f
find = curry (f, xs) -> xs.find f
findIndex = curry (f, xs) -> xs.findIndex f

first = ([x, xs...]) -> x
last = ([xs..., x]) -> x
rest = ([x, xs...]) -> xs
initial = ([xs..., x]) -> xs

# ── Object ops ───────────────────────────────
extend = (a, bs...) ->
  for b in bs
    for own k, v of b
      a[k] = v
  a

pick = curry (keys, obj) ->
  keys.reduce ((acc, k) -> acc[k] = obj[k]; acc), {}

omit = curry (keys, obj) ->
  result = {}
  for own k, v of obj
    result[k] = v unless k in keys
  result

values = (obj) -> (v for own _, v of obj)
entries = (obj) -> ([k, v] for own k, v of obj)

# ── Predicates ───────────────────────────────
notF = (f) -> (as...) -> not f as...
eq = curry (x, y) -> y is x
notEq = curry (x, y) -> y isnt x
isType = curry (t, x) -> Object::toString.call(x).slice(8, -1) is t
isArray = isType 'Array'
isObject = isType 'Object'
isFunction = isType 'Function'
isString = isType 'String'
isNumber = isType 'Number'

# ── React event helpers ────────────────────────
# callWith(f, a)         → () -> f(a)
# valueFromEvent(f)      → (e) -> f(e.target.value)
# fromEvent(f)           → (e) -> f(e)
# targetFromEvent(f)     → (e) -> f(e.target)
# intFromEvent(f, as...) → (e) -> f(as..., parseInt(e.target.value))
# floatFromEvent(f, as...) → (e) -> f(as..., parseFloat(e.target.value))
# parsedFromEvent(f, parse, as...) → (e) -> f(as..., parse(e.target.value))
callWith = (f, a) -> -> f a
valueFromEvent = (f) -> (e) -> f e.target.value
fromEvent = (f) -> (e) -> f e
targetFromEvent = (f) -> (e) -> f e.target
intFromEvent = (f, as...) -> (e) -> f as..., parseInt e.target.value
floatFromEvent = (f, as...) -> (e) -> f as..., parseFloat e.target.value
parsedFromEvent = (f, parse, as...) -> (e) -> f as..., parse e.target.value

# ── Result type (Ok/Err) ─────────────────────
# Pattern: Railway-oriented programming
#   Functions return Ok(value) or Err(error).
#   Callers match on the variant instead of try/catch.

Ok = (value) ->
  ok: true
  value: value
  error: null
  map: (f) -> Ok(f value)
  flatMap: (f) -> f(value)
  match: (onOk, onErr) -> onOk(value)
  unwrap: -> value
  unwrapOr: (fallback) -> value

Err = (error) ->
  ok: false
  value: null
  error: error
  map: (f) -> Err(error)
  flatMap: (f) -> Err(error)
  match: (onOk, onErr) -> onErr(error)
  unwrap: -> throw new Error("Unwrap on Err: #{error}")
  unwrapOr: (fallback) -> fallback

Result =
  ok:    (v) -> Ok(v)
  err:   (e) -> Err(e)
  from:  (f) -> (as...) -> try Ok(f(as...)) catch e then Err(e.message)
  all:   (results) ->
    for r in results
      return r unless r.ok
    Ok(results.map((r) -> r.value))

# ── Maybe type ───────────────────────────────
Maybe = (value) ->
  isNothing: -> not value?
  map: (f) -> if value? then Maybe(f(value)) else Maybe(null)
  flatMap: (f) -> if value? then f(value) else Maybe(null)
  unwrap: -> value
  unwrapOr: (fallback) -> if value? then value else fallback
  tap: (f) -> f(value) if value?; Maybe(value)
  get: (prop) -> if value? then Maybe(value[prop]) else Maybe(null)

# ── Pattern matching ─────────────────────────
match = (value, cases) ->
  fn = cases[value] or cases._
  if fn then fn() else undefined

# ── Pipeline operator style ──────────────────
thrush = (x, fs...) -> (x = f(x)) for f in fs; x

# ── Conditional CSS ──────────────────────────
# classNames('base', ['mod', cond], ...) → "base mod" or "base"
classNames = (base, mods...) ->
  out = base
  for m in mods
    out += " #{m[0]}" if m[1]
  out

# ── Number formatting ────────────────────────
fmt0 = (n) -> (n || 0).toFixed(0)
fmt1 = (n) -> (n || 0).toFixed(1)
fmt2 = (n) -> (n || 0).toFixed(2)

# ── String ───────────────────────────────────
upper = (s) -> s.charAt(0).toUpperCase() + s.slice 1
lower = (s) -> s.charAt(0).toLowerCase() + s.slice 1
fmt = curry (str, args...) ->
  str.replace /%(\\d+)/g, (_, i) -> args[--i] or ''

# ── Exports ──────────────────────────────────
export {
  _, id, K
  builtin, toArray, variadic
  curry, apply, partial
  compose, sequence, pipe
  fold, map, filter, each, any, all, find, findIndex
  first, last, rest, initial
  extend, pick, omit, values, entries
  notF, eq, notEq, isType, isArray, isObject, isFunction, isString, isNumber
  callWith, valueFromEvent, fromEvent, targetFromEvent
  intFromEvent, floatFromEvent, parsedFromEvent
  classNames
  fmt0, fmt1, fmt2
  upper, lower, fmt
  Result, Maybe, match, thrush
}