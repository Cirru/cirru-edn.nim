
import cirruParser
import cirruEdn/types
import re
import strutils
import sequtils
import tables

proc mapExpr(tree: CirruNode): CirruEdnValue =

  case tree.kind:
  of cirruString:
    case tree.text:
    of "true":
      return CirruEdnValue(kind: crEdnBool, boolVal: true)
    of "false":
      return CirruEdnValue(kind: crEdnBool, boolVal: false)
    of "nil":
      return CirruEdnValue(kind: crEdnNil)
    else:
      if tree.text == "":
        raise newException(EdnEmptyError, "\"\" is not valid data ")
      elif tree.text[0] == ':':
        return CirruEdnValue(kind: crEdnKeyword, keywordVal: tree.text[1..tree.text.high])
      elif tree.text[0] == '|':
        return CirruEdnValue(kind: crEdnString, stringVal: tree.text[1..tree.text.high])
      elif tree.text[0] == '"':
        return CirruEdnValue(kind: crEdnString, stringVal: tree.text[1..tree.text.high])
      elif match($(tree.text[0]), re"\d+(.\d+)?"):
        return CirruEdnValue(kind: crEdnNumber, numberVal: parseFloat(tree.text))
      else:
        echo tree.text
        raise newException(EdnInvalidError, "Unknown data")
  of cirruSeq:
    if tree.list.len == 0:
      raise newException(EdnInvalidError, "[] is not a valid expression")
    let firstNode = tree.list[0]
    if firstNode.kind == cirruSeq:
      raise newException(EdnInvalidError, "nested expr is not supported as operator")
    case firstNode.text:
      of "[]":
        let body: seq[CirruNode] = tree.list[1..tree.list.high]
        return CirruEdnValue(kind: crEdnVector, vectorVal: body.map(mapExpr))
      of "list":
        return CirruEdnValue(kind: crEdnList, listVal: @[])
      of "{}":
        return CirruEdnValue(kind: crEdnMap, mapVal: initTable[CirruEdnValue, CirruEdnValue]())

proc parseEdnFromStr*(code: string): CirruEdnValue =
  let tree = parseCirru code

  case tree.kind:
  of cirruString:
    raise newException(EdnInvalidError, "does not handle raw string from Cirru parser")
  of cirruSeq:
    if tree.list.len == 0:
      raise newException(EdnEmptyError, "[] represents no value")
    elif tree.list.len > 1:
      raise newException(EdnInvalidError, "has too many expressions")
    let dataNode = tree.list[0]
    case dataNode.kind:
    of cirruString:
      raise newException(EdnInvalidError, "does not handle raw string from Cirru parser")
    of cirruSeq:
      let firstNode = dataNode.list[0]
      case firstNode.kind:
      of cirruString:
        case firstNode.text:
        of "do":
          if dataNode.list.len == 2:
            return mapExpr(dataNode.list[1])
        of "[]":
          return mapExpr(dataNode)
        of "{}":
          return mapExpr(dataNode)
        of "list":
          return mapExpr(dataNode)
        else:
          echo "Node text: ", escape(firstNode.text)
          raise newException(EdnInvalidError, "Unknown operation")
      of cirruSeq:
        raise newException(EdnInvalidError, "does not support expression as command")

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

    of crEdnFn:
      echo "TODO compare"
      return true
    of crEdnMap:
      echo "TODO compare"
      return true