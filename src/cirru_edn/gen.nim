
import tables
import sets

import ./types

proc genCrEdn*(x: int): CirruEdnValue =
  CirruEdnValue(kind: crEdnNumber, numberVal: x.float)

proc genCrEdn*(x: float): CirruEdnValue =
  CirruEdnValue(kind: crEdnNumber, numberVal: x)

proc genCrEdn*(x: bool): CirruEdnValue =
  CirruEdnValue(kind: crEdnBool, boolVal: x)

proc genCrEdn*(x: string, asKeyword: bool = false): CirruEdnValue =
  CirruEdnValue(kind: crEdnString, stringVal: x)

proc genCrEdnKeyword*(x: string, asKeyword: bool = false): CirruEdnValue =
  CirruEdnValue(kind: crEdnKeyword, keywordVal: x)

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

