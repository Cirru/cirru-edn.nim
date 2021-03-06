import tables
import strutils
import sequtils
import sets

import ./types

proc toString*(val: CirruEdnValue): string

proc fromArrayToString(children: seq[CirruEdnValue]): string =
  return "[" & children.mapIt(toString(it)).join(" ") & "]"

proc fromSeqToString(children: seq[CirruEdnValue]): string =
  return "(" & children.mapIt(toString(it)).join(" ") & ")"

proc fromSetToString(children: HashSet[CirruEdnValue]): string =
  return "#{" & children.mapIt(toString(it)).join(" ") & "}"

proc fromTableToString(children: Table[CirruEdnValue, CirruEdnValue]): string =
  let size = children.len()
  if size > 20:
    return "{...(20)...}"
  var tableStr = "{"
  var counted = 0
  for k, child in pairs(children):
    tableStr = tableStr & toString(k) & " " & toString(child)
    counted = counted + 1
    if counted < children.len:
      tableStr = tableStr & ", "
  tableStr = tableStr & "}"
  return tableStr

proc formRecordToString(name: string, fields: seq[string], values: seq[CirruEdnValue]): string =
  result = "%{" & name
  if fields.len != values.len:
    raise newException(EdnInvalidError, "Expected fields and values has same size")
  for idx, field in fields:
    if idx == 0:
      result &= " "
    else:
      result &= ", "
    result &= field & " " & toString(values[idx])
  result &= "}"

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
    of crEdnSet: fromSetToString(val.setVal)
    of crEdnMap: fromTableToString(val.mapVal)
    of crEdnRecord: formRecordToString(val.recordName, val.recordFields, val.recordValues)
    of crEdnNil: "nil"
    of crEdnKeyword: ":" & val.keywordVal
    of crEdnSymbol: "'" & val.keywordVal
    of crEdnQuotedCirru: $(val.quotedVal)

proc `$`*(v: CirruEdnValue): string =
  v.toString
