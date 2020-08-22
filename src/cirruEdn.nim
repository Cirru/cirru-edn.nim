
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
        let body: seq[CirruNode] = tree.list[1..tree.list.high]
        return CirruEdnValue(kind: crEdnList, listVal: body.map(mapExpr))
      of "{}":
        var dict = initTable[CirruEdnValue, CirruEdnValue]()
        for k, pair in tree.list[1..tree.list.high]:
          if pair.kind == cirruString:
            echo $pair
            raise newException(EdnInvalidError, "Must be pairs in a map")
          if pair.list.len != 2:
            echo $pair
            raise newException(EdnInvalidError, "Must be pair of 2 in a map")
          let k = mapExpr pair.list[0]
          let v = mapExpr pair.list[1]
          dict[k] = v
        return CirruEdnValue(kind: crEdnMap, mapVal: dict)

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
