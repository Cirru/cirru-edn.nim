import tables
import hashes

type
  CirruEdnKind* = enum
    crEdnNil,
    crEdnBool,
    crEdnNumber,
    crEdnString,
    crEdnKeyword,
    crEdnVector,
    crEdnList,
    crEdnMap,
    crEdnFn

  CirruEdnValue* = object
    case kind*: CirruEdnKind
    of crEdnNil: discard
    of crEdnBool: boolVal*: bool
    of crEdnNumber: numberVal*: float
    of crEdnString: stringVal*: string
    of crEdnKeyword: keywordVal*: string
    of crEdnFn: fnVal*: proc()
    of crEdnVector: vectorVal*: seq[CirruEdnValue]
    of crEdnList: listVal*: seq[CirruEdnValue]
    of crEdnMap: mapVal*: Table[CirruEdnValue, CirruEdnValue]

  EdnEmptyError* = object of ValueError
  EdnInvalidError* = object of ValueError

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
      result =  hash("fn:")
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
    of crEdnMap:
      result = hash("map:")
      for k, v in value.mapVal.pairs:
        result = result !& hash(k)
        result = result !& hash(v)

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

    of crEdnMap:
      if x.mapVal.len != y.mapVal.len:
        return false

      for k, v in x.mapVal.pairs:
        if not (y.mapVal.hasKey(k) and y.mapVal[k] == v):
          return false

      return true

proc `!=`*(x, y: CirruEdnValue): bool =
  not (x == y)
