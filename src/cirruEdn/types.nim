import tables
import hashes
import sets

import cirruParser

type
  CirruEdnKind* = enum
    crEdnNil,
    crEdnBool,
    crEdnNumber,
    crEdnString,
    crEdnKeyword,
    crEdnVector,
    crEdnList,
    crEdnSet,
    crEdnMap,
    crEdnFn,
    crEdnQuotedCirru,

  CirruEdnValue* = object
    line*: int
    column*: int
    case kind*: CirruEdnKind
    of crEdnNil: discard
    of crEdnBool: boolVal*: bool
    of crEdnNumber: numberVal*: float
    of crEdnString: stringVal*: string
    of crEdnKeyword: keywordVal*: string
    of crEdnFn:
      fnVal*: proc(exprList: seq[CirruEdnValue], interpret: proc(expr: CirruNode): CirruEdnValue): CirruEdnValue
    of crEdnVector: vectorVal*: seq[CirruEdnValue]
    of crEdnList: listVal*: seq[CirruEdnValue]
    of crEdnSet: setVal*: HashSet[CirruEdnValue]
    of crEdnMap: mapVal*: Table[CirruEdnValue, CirruEdnValue]
    of crEdnQuotedCirru: quotedVal*: CirruNode

  EdnEmptyError* = object of ValueError
  EdnInvalidError* = object of ValueError
  EdnOpError* = object of ValueError

proc hash*(value: CirruNode): Hash =
  case value.kind:
  of cirruString:
    return hash(value.text)
  of cirruSeq:
    result = hash("cirruSeq:")
    for x in value.list:
      result = result !& hash(x)
    result = !$ result

proc hash*(value: CirruEdnValue): Hash =
  case value.kind
    of crEdnNumber:
      return hash("number:" & $value.numberVal)
    of crEdnString:
      return hash("string:" & value.stringVal)
    of crEdnNil:
      return hash("nil:")
    of crEdnBool:
      return hash("bool:" & $(value.boolVal))
    of crEdnKeyword:
      return hash("keyword:" & value.keywordVal)
    of crEdnFn:
      result = hash("fn:")
      result = result !& hash(value.fnVal)
      result = !$ result
    of crEdnVector:
      result = hash("vector:")
      for idx, x in value.vectorVal:
        result = result !& hash(x)
      result = !$ result
    of crEdnList:
      result = hash("list:")
      for idx, x in value.listVal:
        result = result !& hash(x)
      result = !$ result
    of crEdnSet:
      result = hash("set:")
      for x in value.setVal.items:
        result = result !& hash(x)
      result = !$ result
    of crEdnMap:
      result = hash("map:")
      for k, v in value.mapVal.pairs:
        result = result !& hash(k)
        result = result !& hash(v)

      result = !$ result

    of crEdnQuotedCirru:
      result =  hash("quoted:")
      result = result !& hash(value.quotedVal)
      result = !$ result

proc `==`*(x, y: CirruEdnValue): bool =
  if x.kind != y.kind:
    return false
  else:
    case x.kind:
    of crEdnNil:
      return true
    of crEdnBool:
      return x.boolVal == y.boolVal
    of crEdnString:
      return x.stringVal == y.stringVal
    of crEdnNumber:
      return x.numberVal == y.numberVal
    of crEdnKeyword:
      return x.keywordVal == y.keywordVal
    of crEdnFn:
      return x.fnVal == y.fnVal

    of crEdnVector:
      if x.vectorVal.len != y.vectorVal.len:
        return false
      for idx, xi in x.vectorVal:
        if xi != y.vectorVal[idx]:
          return false
      return true

    of crEdnList:
      if x.listVal.len != y.listVal.len:
        return false

      for idx, xi in x.listVal:
        if xi != y.listVal[idx]:
          return false
      return true

    of crEdnSet:
      if x.setVal.len != y.setVal.len:
        return false

      for xi in x.setVal.items:
        if not y.setVal.contains(xi):
          return false
      return true

    of crEdnMap:
      if x.mapVal.len != y.mapVal.len:
        return false

      for k, v in x.mapVal.pairs:
        if not (y.mapVal.hasKey(k) and y.mapVal[k] == v):
          return false

      return true

    of crEdnQuotedCirru:
      return x.quotedVal == y.quotedVal

proc `!=`*(x, y: CirruEdnValue): bool =
  not (x == y)

iterator items*(x: CirruEdnValue): CirruEdnValue =
  case x.kind:
  of crEdnList:
    for i, child in x.listVal:
      yield child

  of crEdnVector:
    for i, child in x.vectorVal:
      yield child

  of crEdnSet:
    for child in x.setVal.items:
      yield child

  else:
    raise newException(EdnOpError, "data is not iterable as a sequence")

iterator pairs*(x: CirruEdnValue): tuple[k: CirruEdnValue, v: CirruEdnValue] =
  if x.kind != crEdnMap:
    raise newException(EdnOpError, "data is not iterable as map")

  for k, v in x.mapVal:
    yield (k, v)
