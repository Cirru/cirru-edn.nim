
import strutils
import sequtils
import tables
import sets
import options

import cirru_parser
import cirru_writer

import cirru_edn/types
import cirru_edn/format
import cirru_edn/gen
import cirru_edn/util
import cirru_edn/str_util

export CirruEdnValue, CirruEdnKind, `$`, `==`, `!=`
export EdnEmptyError, EdnInvalidError, EdnOpError
export map, mapPairs, items, pairs, hash, get, contains, toJson, toCirruEdn
export genCrEdn, genCrEdnKeyword, genCrEdnList, genCrEdnVector, genCrEdnSet, genCrEdnMap

proc mapExpr(tree: CirruNode): CirruEdnValue =

  case tree.kind:
  of cirruString:
    case tree.text:
    of "true":
      return CirruEdnValue(kind: crEdnBool, boolVal: true, line: tree.line, column: tree.column)
    of "false":
      return CirruEdnValue(kind: crEdnBool, boolVal: false, line: tree.line, column: tree.column)
    of "nil":
      return CirruEdnValue(kind: crEdnNil)
    else:
      if tree.text == "":
        raise newException(EdnEmptyError, "\"\" is not valid data ")
      elif tree.text[0] == ':':
        return CirruEdnValue(kind: crEdnKeyword, keywordVal: tree.text[1..tree.text.high], line: tree.line, column: tree.column)
      elif tree.text[0] == '|':
        return CirruEdnValue(kind: crEdnString, stringVal: tree.text[1..tree.text.high], line: tree.line, column: tree.column)
      elif tree.text[0] == '"':
        return CirruEdnValue(kind: crEdnString, stringVal: tree.text[1..tree.text.high], line: tree.line, column: tree.column)
      elif tree.text.matchesFloat():
        return CirruEdnValue(kind: crEdnNumber, numberVal: parseFloat(tree.text), line: tree.line, column: tree.column)
      else:
        echo tree.text
        raise newException(EdnInvalidError, "Unknown data")
  of cirruSeq:
    if tree.isEmpty:
      raise newException(EdnInvalidError, "[] is not a valid expression")
    let firstNode = tree.first.get
    if firstNode.kind == cirruSeq:
      raise newException(EdnInvalidError, "nested expr is not supported as operator")
    case firstNode.text:
      of "[]":
        let body: seq[CirruNode] = tree[1..^1]
        return CirruEdnValue(kind: crEdnVector, vectorVal: body.map(mapExpr), line: tree.line, column: tree.column)
      of "list":
        let body: seq[CirruNode] = tree[1..^1]
        return CirruEdnValue(kind: crEdnList, listVal: body.map(mapExpr), line: tree.line, column: tree.column)
      of "set", "#{}":
        let body: seq[CirruNode] = tree[1..^1]
        return CirruEdnValue(kind: crEdnSet, setVal: toHashSet(body.map(mapExpr)), line: tree.line, column: tree.column)
      of "{}":
        var dict = initTable[CirruEdnValue, CirruEdnValue]()
        for k, pair in tree[1..^1]:
          if pair.kind == cirruString:
            echo $pair
            raise newException(EdnInvalidError, "Must be pairs in a map")
          if pair.len != 2:
            echo $pair
            raise newException(EdnInvalidError, "Must be pair of 2 in a map")
          let k = mapExpr pair[0].get
          let v = mapExpr pair[1].get
          dict[k] = v
        return CirruEdnValue(kind: crEdnMap, mapVal: dict, line: tree.line, column: tree.column)
      of "quote":
        if tree.len != 2:
          raise newException(EdnInvalidError, "quote requires only 1 item")
        return CirruEdnValue(kind: crEdnQuotedCirru, quotedVal: tree[1].get)

proc parseCirruEdn*(code: string): CirruEdnValue =
  let tree = parseCirru code

  case tree.kind:
  of cirruString:
    raise newException(EdnInvalidError, "does not handle raw string from Cirru parser")
  of cirruSeq:
    if tree.len == 0:
      raise newException(EdnEmptyError, "[] represents no value")
    elif tree.len > 1:
      raise newException(EdnInvalidError, "has too many expressions")
    let dataNode = tree[0].get
    case dataNode.kind:
    of cirruString:
      raise newException(EdnInvalidError, "does not handle raw string from Cirru parser")
    of cirruSeq:
      let firstNode = dataNode[0].get
      case firstNode.kind:
      of cirruString:
        case firstNode.text:
        of "do":
          if dataNode.len == 2:
            return mapExpr(dataNode[1].get)
        of "[]":
          return mapExpr(dataNode)
        of "{}":
          return mapExpr(dataNode)
        of "list":
          return mapExpr(dataNode)
        of "set", "#{}":
          return mapExpr(dataNode)
        of "quote":
          return mapExpr(dataNode)
        else:
          echo "Node text: ", escape(firstNode.text)
          raise newException(EdnInvalidError, "Unknown operation")
      of cirruSeq:
        raise newException(EdnInvalidError, "does not support expression as command")

proc transformToWriter(xs: CirruNode): CirruWriterNode =
  case xs.kind
  of cirruSeq:
    var buffer = CirruWriterNode(kind: writerList, list: @[])
    for item in xs.list:
      buffer.list.add item.transformToWriter
    buffer
  of cirruString:
    CirruWriterNode(kind: writerItem, item: xs.text)

proc transformToWriter(xs: CirruEdnValue): CirruWriterNode =
  case xs.kind
    of crEdnNil:
      CirruWriterNode(kind: writerItem, item: "nil")
    of crEdnBool:
      CirruWriterNode(kind: writerItem, item: $xs.boolVal)
    of crEdnNumber:
      CirruWriterNode(kind: writerItem, item: $xs.numberVal)
    of crEdnString:
      let str = "|" & xs.stringVal
      CirruWriterNode(kind: writerItem, item: str)
    of crEdnKeyword:
      CirruWriterNode(kind: writerItem, item: ":" & $xs.keywordVal)
    of crEdnVector:
      var buffer = CirruWriterNode(kind: writerList, list: @[])
      buffer.list.add CirruWriterNode(kind: writerItem, item: "[]")
      for item in xs.vectorVal:
        buffer.list.add item.transformToWriter
      buffer

    of crEdnList:
      var buffer = CirruWriterNode(kind: writerList, list: @[])
      buffer.list.add CirruWriterNode(kind: writerItem, item: "list")
      for item in xs.listVal:
        buffer.list.add item.transformToWriter
      buffer

    of crEdnSet:
      var buffer = CirruWriterNode(kind: writerList, list: @[])
      buffer.list.add CirruWriterNode(kind: writerItem, item: "#{}")
      for item in xs.setVal:
        buffer.list.add item.transformToWriter
      buffer

    of crEdnMap:
      var buffer = CirruWriterNode(kind: writerList, list: @[])
      buffer.list.add CirruWriterNode(kind: writerItem, item: "{}")
      for k, item in xs.mapVal:
        var pair  = CirruWriterNode(kind: writerList, list: @[])
        pair.list.add(k.transformToWriter)
        pair.list.add(item.transformToWriter)
        buffer.list.add pair
      buffer

    of crEdnQuotedCirru:
      var buffer = CirruWriterNode(kind: writerList, list: @[])
      buffer.list.add CirruWriterNode(kind: writerItem, item: "quote")
      buffer.list.add xs.quotedVal.transformToWriter
      buffer

proc formatToCirru*(xs: CirruEdnValue, useInline: bool = false): string =
  case xs.kind
  of crEdnNil, crEdnNumber, crEdnString, crEdnBool, crEdnKeyword:
    let writer0 = CirruWriterNode(kind: writerList, list: @[
      CirruWriterNode(kind: writerItem, item: "do"),
      xs.transformToWriter
    ])
    # wrap with an extra list since writer handles LINES of expressions
    let writer1 = CirruWriterNode(kind: writerList, list: @[writer0])
    writer1.writeCirruCode((useInline: useInline))
  else:
    let writer = CirruWriterNode(kind: writerList, list: @[xs.transformToWriter])
    writer.writeCirruCode((useInline: useInline))
