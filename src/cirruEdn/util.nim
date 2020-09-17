
import sequtils
import sets
import tables
import json

import cirruParser
import cirruEdn/types

proc map*[T](xs: CirruEdnValue, f: proc (x: CirruEdnValue): T): seq[T] =
  case xs.kind:
  of crEdnList:
    return xs.listVal.map(f)
  of crEdnVector:
    return xs.vectorVal.map(f)
  of crEdnSet:
    var list = newSeq[CirruEdnValue]()
    for x in xs.setVal.items:
      list.add x
    return list.map(f)
  else:
    raise newException(EdnOpError, "map does not work on Cirru EDN literals")

proc mapPairs*[T](xs: CirruEdnValue, f: proc (p: tuple[k: CirruEdnValue, v: CirruEdnValue]): T): seq[T] =
  case xs.kind:
  of crEdnMap:
    var ys: seq[tuple[k:CirruEdnValue, v:CirruEdnValue]] = @[]
    for k, v in xs.mapVal:
      ys.add (k, v)
    return ys.map(f)

  else:
    raise newException(EdnOpError, "map does not work on Cirru EDN literals")

proc contains*(x: CirruEdnValue, k: CirruEdnValue): bool =
  if x.kind != crEdnMap:
    raise newException(EdnOpError, "hasKey only works for a map")
  return x.mapVal.hasKey(k)

proc get*(x: CirruEdnValue, k: CirruEdnValue): CirruEdnValue =
  case x.kind:
  of crEdnMap:
    if x.contains(k):
      return x.mapVal[k]
    else:
      return CirruEdnValue(kind: crEdnNil)
  else:
    raise newException(EdnOpError, "can't run get on a literal or seq")

proc toJson*(x: CirruEdnValue): JsonNode =
  case x.kind:
  of crEdnNil:
    return JsonNode(kind: JNull)
  of crEdnBool:
    return JsonNode(kind: JBool, bval: x.boolVal)
  of crEdnNumber:
    return JsonNode(kind: JFloat, fnum: x.numberVal)
  of crEdnString:
    return JsonNode(kind: JString, str: x.stringVal)
  of crEdnKeyword:
    return JsonNode(kind: JString, str: x.keywordVal)
  of crEdnList:
    var elems: seq[JsonNode] = @[]
    for i, child in x.listVal:
      elems.add toJson(child)
    return JsonNode(kind: JArray, elems: elems)
  of crEdnVector:
    var elems: seq[JsonNode] = @[]
    for i, child in x.vectorVal:
      elems.add toJson(child)
    return JsonNode(kind: JArray, elems: elems)
  of crEdnSet:
    var elems: seq[JsonNode] = @[]
    for child in x.setVal.items:
      elems.add toJson(child)
    return JsonNode(kind: JArray, elems: elems)
  of crEdnMap:
    var fields: OrderedTable[string, JsonNode]
    for k, v in x.mapVal.pairs():
      case k.kind:
      of crEdnString:
        fields[k.stringVal] = toJson(v)
      of crEdnKeyword:
        fields[k.keywordVal] = toJson(v)
      else:
        raise newException(EdnOpError, "required string keys in JObject")
    return JsonNode(kind: JObject, fields: fields)

  of crEdnQuotedCirru:
    return toJson(x.quotedVal)

# notice that JSON does not have keywords or some other types
proc toCirruEdn*(v: JsonNode): CirruEdnValue =
  case v.kind
  of JString:
    return CirruEdnValue(kind: crEdnString, stringVal: v.str)
  of JInt:
    return CirruEdnValue(kind: crEdnNumber, numberVal: v.to(float))
  of JFloat:
    return CirruEdnValue(kind: crEdnNumber, numberVal: v.fnum)
  of JBool:
    return CirruEdnValue(kind: crEdnBool, boolVal: v.bval)
  of JNull:
    return CirruEdnValue(kind: crEdnNil)
  of JArray:
    var arr: seq[CirruEdnValue]
    for v in v.elems:
      arr.add toCirruEdn(v)
    return CirruEdnValue(kind: crEdnVector, vectorVal: arr)
  of JObject:
    var table = initTable[CirruEdnValue, CirruEdnValue]()
    for key, value in v:
      let keyContent = CirruEdnValue(kind: crEdnString, stringVal: key)
      let value = toCirruEdn(value)
      table.add(keyContent, value)
    return CirruEdnValue(kind: crEdnMap, mapVal: table)
