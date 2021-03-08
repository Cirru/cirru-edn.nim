
import tables
import sets
import algorithm

import ./types

proc genCrEdn*(x: int): CirruEdnValue =
  CirruEdnValue(kind: crEdnNumber, numberVal: x.float)

proc genCrEdn*(x: float): CirruEdnValue =
  CirruEdnValue(kind: crEdnNumber, numberVal: x)

proc genCrEdn*(x: bool): CirruEdnValue =
  CirruEdnValue(kind: crEdnBool, boolVal: x)

proc genCrEdn*(x: string): CirruEdnValue =
  CirruEdnValue(kind: crEdnString, stringVal: x)

proc genCrEdnKeyword*(x: string): CirruEdnValue =
  CirruEdnValue(kind: crEdnKeyword, keywordVal: x)

proc genCrEdnSymbol*(x: string): CirruEdnValue =
  CirruEdnValue(kind: crEdnSymbol, symbolVal: x)

proc genCrEdn*(): CirruEdnValue =
  CirruEdnValue(kind: crEdnNil)

proc genCrEdnList*(xs: varargs[CirruEdnValue]): CirruEdnValue =
  var ys: seq[CirruEdnValue]
  for item in xs:
    ys.add item
  CirruEdnValue(kind: crEdnList, listVal: ys)

proc genCrEdnVector*(xs: varargs[CirruEdnValue]): CirruEdnValue =
  var ys: seq[CirruEdnValue]
  for item in xs:
    ys.add item
  CirruEdnValue(kind: crEdnVector, vectorVal: ys)

proc genCrEdnSet*(xs: varargs[CirruEdnValue]): CirruEdnValue =
  CirruEdnValue(kind: crEdnSet, setVal: toHashSet(xs))

proc genCrEdnMap*(xs: varargs[CirruEdnValue]): CirruEdnValue =
  if xs.len %% 2 != 0:
    raise newException(ValueError, "Map generator expects even number of arguments")
  let size = (xs.len / 2).int
  result = CirruEdnValue(kind: crEdnMap, mapVal: initTable[CirruEdnValue, CirruEdnValue]())
  for i in 0..<size:
    result.mapVal[xs[i * 2]] = xs[i * 2 + 1]

proc genCrEdnRecord*(name: string, xs: varargs[CirruEdnValue]): CirruEdnValue =
  if xs.len %% 2 != 0:
    raise newException(ValueError, "Record generator expects even number of arguments")

  let size = (xs.len / 2).int
  result = CirruEdnValue(kind: crEdnMap, mapVal: initTable[CirruEdnValue, CirruEdnValue]())

  var pairs: seq[RecordInPair]

  for i in 0..<size:
    var field: string
    let fieldNode = xs[i * 2]

    if fieldNode.kind == crEdnString:
      field = fieldNode.stringVal
    elif fieldNode.kind == crEdnKeyword:
      field = fieldNode.stringVal
    else:
      raise newException(ValueError, "Expected primative values " & $fieldNode)
    pairs.add((field, xs[i * 2 + 1]))

  pairs.sort(recordFieldOrder)

  var fields: seq[string]
  var values: seq[CirruEdnValue]
  for pair in pairs:
    fields.add pair.k
    values.add pair.v

  return CirruEdnValue(
    kind: crEdnRecord, recordName: name,
    recordFields: fields, recordValues: values,
  )
