import tables
import strutils
import sequtils

import cirruEdn/types

proc toString*(val: CirruEdnValue): string

proc fromArrayToString(children: seq[CirruEdnValue]): string =
  return "[" & children.mapIt(toString(it)).join(" ") & "]"

proc fromSeqToString(children: seq[CirruEdnValue]): string =
  return "(" & children.mapIt(toString(it)).join(" ") & ")"

proc fromTableToString(children: Table[CirruEdnValue, CirruEdnValue]): string =
  let size = children.len()
  if size > 20:
    return "{...(20)...}"
  var tableStr = "{"
  for k, child in pairs(children):
    tableStr = tableStr & toString(k) & " " & toString(child) & ", "
  tableStr = tableStr & "}"
  return tableStr

proc toString*(val: CirruEdnValue): string =
  case val.kind:
    of crEdnBool:
      if val.boolVal:
        "true"
      else:
        "false"
    of crEdnNumber: $(val.numberVal)
    of crEdnString: escape(val.stringVal)
    of crEdnVector: fromArrayToString(val.vectorVal)
    of crEdnList: fromSeqToString(val.listVal)
    of crEdnMap: fromTableToString(val.mapVal)
    of crEdnNil: "nil"
    of crEdnKeyword: ":" & val.keywordVal
    of crEdnFn: "::fn"

proc `$`*(v: CirruEdnValue): string =
  v.toString
