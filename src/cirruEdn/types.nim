import strutils
import sequtils, sugar
import tables
import hashes
import strformat

type
  CirruEdnKind* = enum
    crEdnNil,
    crEdnBool,
    crEdnNumber,
    crEdnString,
    crEdnKeyword,
    crEdnVector,
    crEdnSeq,
    crEdnTable,
    crEdnFn

  TablePair* = tuple[key: CirruEdnValue, value: CirruEdnValue]

  CirruEdnValue* = object
    case kind*: CirruEdnKind
    of crEdnNil: discard
    of crEdnBool: boolVal*: bool
    of crEdnNumber: numberVal*: float
    of crEdnString: stringVal*: string
    of crEdnKeyword: keywordVal*: string
    of crEdnFn: fnVal*: proc()
    of crEdnVector: vectorVal*: seq[CirruEdnValue]
    of crEdnSeq: seqVal*: seq[CirruEdnValue]
    of crEdnTable: tableVal*: Table[Hash, TablePair]

  EdnEmptyError* = object of Exception
  EdnInvalidError* = object of Exception

proc toString*(val: CirruEdnValue): string

proc fromArrayToString(children: seq[CirruEdnValue]): string =
  return "[" & children.mapIt(toString(it)).join(" ") & "]"

proc fromSeqToString(children: seq[CirruEdnValue]): string =
  return "(" & children.mapIt(toString(it)).join(" ") & ")"

proc fromTableToString(children: Table[Hash, TablePair]): string =
  let size = children.len()
  if size > 20:
    return "{...(20)...}"
  var tableStr = "{"
  for k, child in pairs(children):
    # TODO, need a way to get original key
    tableStr = tableStr & toString(child.key) & " " & toString(child.value) & ", "
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
    of crEdnSeq: fromSeqToString(val.seqVal)
    of crEdnTable: fromTableToString(val.tableVal)
    else: "::CirruEdnValue::"

proc hashCirruEdnValue*(value: CirruEdnValue): Hash =
  case value.kind
    of crEdnNumber:
      return hash(value.numberVal)
    of crEdnString:
      return hash(value.stringVal)
    of crEdnNil:
      # TODO not safe enough
      return hash("")
    of crEdnBool:
      # TODO not safe enough
      return hash(fmt"{value.boolVal}")
    of crEdnVector:
      return hash("TODO")
    else:
      # TODO
      return hash("TODO")
