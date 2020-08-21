
import tables
import cirruEdn/types

proc crEdn*(x: int): CirruEdnValue =
  CirruEdnValue(kind: crEdnNumber, numberVal: x.float)

proc crEdn*(x: float): CirruEdnValue =
  CirruEdnValue(kind: crEdnNumber, numberVal: x)

proc crEdn*(x: bool): CirruEdnValue =
  CirruEdnValue(kind: crEdnBool, boolVal: x)

proc crEdn*(x: string, asKeyword: bool = false): CirruEdnValue =
  if asKeyword:
    CirruEdnValue(kind: crEdnKeyword, keywordVal: x)
  else:
    CirruEdnValue(kind: crEdnString, stringVal: x)

proc crEdn*(): CirruEdnValue =
  CirruEdnValue(kind: crEdnNil)

proc crEdn*(xs: seq[CirruEdnValue], asList: bool = false): CirruEdnValue =
  if asList:
    CirruEdnValue(kind: crEdnList, listVal: xs)
  else:
    CirruEdnValue(kind: crEdnVector, vectorVal: xs)

proc crEdn*(xs: Table[CirruEdnValue, CirruEdnValue]): CirruEdnValue =
  CirruEdnValue(kind: crEdnMap, mapVal: xs)
