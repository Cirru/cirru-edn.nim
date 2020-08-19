
import cirruParser
import cirruEdn/types
import re

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
        return CirruEdnValue(kind: crEdnKeyword, keywordVal: tree.text[1..^0])
      elif tree.text[0] == '|':
        return CirruEdnValue(kind: crEdnString, stringVal: tree.text[1..^0])
      elif tree.text[0] == '"':
        return CirruEdnValue(kind: crEdnString, stringVal: tree.text[1..^0])
      elif match($(tree.text[0]), re"\d"):
        echo "TODO number"
        return CirruEdnValue(kind: crEdnNumber, numberVal: 0)
      else:
        echo tree.text
        raise newException(EdnInvalidError, "Unknown data")
  of cirruSeq:
    return CirruEdnValue(kind: crEdnString, stringVal: "TODO Seq")

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
        else:
          echo "Node text:", firstNode.text
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
      echo "TODO compare"
      return true
    of crEdnSeq:
      echo "TODO compare"
      return true
    of crEdnFn:
      echo "TODO compare"
      return true
    of crEdnTable:
      echo "TODO compare"
      return true