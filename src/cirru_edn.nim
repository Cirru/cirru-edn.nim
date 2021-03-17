
import strutils
import sequtils
import tables
import sets
import options
import algorithm
import math

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
export genCrEdn, genCrEdnKeyword, genCrEdnList, genCrEdnVector, genCrEdnSet, genCrEdnMap, genCrEdnRecord, genCrEdnSymbol

proc mapExpr(tree: CirruNode): CirruEdnValue =

  case tree.kind:
  of cirruToken:
    case tree.token:
    of "true":
      return CirruEdnValue(kind: crEdnBool, boolVal: true, line: tree.line, column: tree.column)
    of "false":
      return CirruEdnValue(kind: crEdnBool, boolVal: false, line: tree.line, column: tree.column)
    of "nil":
      return CirruEdnValue(kind: crEdnNil)
    else:
      if tree.token == "":
        raise newException(EdnEmptyError, "\"\" is not valid data ")
      elif tree.token[0] == ':':
        return CirruEdnValue(kind: crEdnKeyword, keywordVal: tree.token[1..tree.token.high], line: tree.line, column: tree.column)
      elif tree.token[0] == '|':
        return CirruEdnValue(kind: crEdnString, stringVal: tree.token[1..tree.token.high], line: tree.line, column: tree.column)
      elif tree.token[0] == '"':
        return CirruEdnValue(kind: crEdnString, stringVal: tree.token[1..tree.token.high], line: tree.line, column: tree.column)
      elif tree.token[0] == '\'':
        return CirruEdnValue(kind: crEdnSymbol, symbolVal: tree.token[1..tree.token.high], line: tree.line, column: tree.column)
      elif tree.token.matchesFloat():
        return CirruEdnValue(kind: crEdnNumber, numberVal: parseFloat(tree.token), line: tree.line, column: tree.column)
      else:
        echo tree.token
        raise newException(EdnInvalidError, "Unknown data")
  of cirruList:
    if tree.isEmpty:
      raise newException(EdnInvalidError, "[] is not a valid expression")
    let firstNode = tree.first.get
    if firstNode.kind == cirruList:
      raise newException(EdnInvalidError, "nested expr is not supported as operator")
    case firstNode.token:
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
          if pair.kind == cirruToken:
            echo $pair
            raise newException(EdnInvalidError, "Must be pairs in a map")
          if pair.len != 2:
            echo $pair, " ", pair.len
            raise newException(EdnInvalidError, "Must be pair of 2 in a map")
          let k = mapExpr pair[0].get
          let v = mapExpr pair[1].get
          dict[k] = v
        return CirruEdnValue(kind: crEdnMap, mapVal: dict, line: tree.line, column: tree.column)
      of "%{}":
        var pairs: seq[RecordInPair]
        let nameNode = tree[1].get()
        if nameNode.kind != cirruToken:
          raise newException(EdnInvalidError, "Expected a token")
        for pair in tree[2..^1]:
          if pair.kind == cirruToken:
            echo $pair
            raise newException(EdnInvalidError, "Must be pairs in a map")
          if pair.len != 2:
            echo $pair, " ", pair.len
            raise newException(EdnInvalidError, "Must be pair of 2 in a map")
          let kNode = pair[0].get
          if kNode.kind != cirruToken:
            echo kNode
            raise newException(EdnInvalidError, "Expected a token")
          let v = mapExpr pair[1].get
          pairs.add((kNode.token, v))

        pairs.sort(recordFieldOrder)

        var fields: seq[string]
        var values: seq[CirruEdnValue]
        for pair in pairs:
          fields.add pair.k
          values.add pair.v
        return CirruEdnValue(
          kind: crEdnRecord, recordName: nameNode.token,
          recordFields: fields, recordValues: values,
        )

      of "quote":
        if tree.len != 2:
          raise newException(EdnInvalidError, "quote requires only 1 item")
        return CirruEdnValue(kind: crEdnQuotedCirru, quotedVal: tree[1].get)

proc parseCirruEdn*(code: string): CirruEdnValue =
  let tree = parseCirru code

  case tree.kind:
  of cirruToken:
    raise newException(EdnInvalidError, "does not handle raw string from Cirru parser")
  of cirruList:
    if tree.len == 0:
      raise newException(EdnEmptyError, "[] represents no value")
    elif tree.len > 1:
      raise newException(EdnInvalidError, "has too many expressions")
    let dataNode = tree[0].get
    case dataNode.kind:
    of cirruToken:
      raise newException(EdnInvalidError, "does not handle raw string from Cirru parser")
    of cirruList:
      let firstNode = dataNode[0].get
      case firstNode.kind:
      of cirruToken:
        case firstNode.token:
        of "do":
          if dataNode.len == 2:
            return mapExpr(dataNode[1].get)
        of "[]":
          return mapExpr(dataNode)
        of "{}":
          return mapExpr(dataNode)
        of "%{}":
          return mapExpr(dataNode)
        of "list":
          return mapExpr(dataNode)
        of "set", "#{}":
          return mapExpr(dataNode)
        of "quote":
          return mapExpr(dataNode)
        else:
          echo "Node text: ", escape(firstNode.token)
          raise newException(EdnInvalidError, "Unknown operation")
      of cirruList:
        raise newException(EdnInvalidError, "does not support expression as command")

proc transformToWriter(xs: CirruNode): CirruWriterNode =
  case xs.kind
  of cirruList:
    var buffer = CirruWriterNode(kind: writerList, list: @[])
    for item in xs.list:
      buffer.list.add item.transformToWriter
    buffer
  of cirruToken:
    CirruWriterNode(kind: writerItem, item: xs.token)

proc transformToWriter(xs: CirruEdnValue): CirruWriterNode =
  case xs.kind
    of crEdnNil:
      CirruWriterNode(kind: writerItem, item: "nil")
    of crEdnBool:
      CirruWriterNode(kind: writerItem, item: $xs.boolVal)
    of crEdnNumber:
      let v = xs.numberVal
      let n = if v.trunc == v: $(v.int) else: $v
      CirruWriterNode(kind: writerItem, item: n)
    of crEdnString:
      let str = "|" & xs.stringVal
      CirruWriterNode(kind: writerItem, item: str)
    of crEdnSymbol:
      let str = "'" & xs.symbolVal
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
        var pair = CirruWriterNode(kind: writerList, list: @[])
        pair.list.add(k.transformToWriter)
        pair.list.add(item.transformToWriter)
        buffer.list.add pair
      buffer

    of crEdnRecord:
      var buffer = CirruWriterNode(kind: writerList, list: @[])
      buffer.list.add CirruWriterNode(kind: writerItem, item: "%{}")
      buffer.list.add CirruWriterNode(kind: writerItem, item: xs.recordName)
      for idx, field in xs.recordFields:
        var pair = CirruWriterNode(kind: writerList, list: @[])
        pair.list.add(CirruWriterNode(kind: writerItem, item: field))
        pair.list.add(xs.recordValues[idx].transformToWriter)
        buffer.list.add pair
      buffer

    of crEdnQuotedCirru:
      var buffer = CirruWriterNode(kind: writerList, list: @[])
      buffer.list.add CirruWriterNode(kind: writerItem, item: "quote")
      buffer.list.add xs.quotedVal.transformToWriter
      buffer

proc formatToCirru*(xs: CirruEdnValue, useInline: bool = false): string =
  case xs.kind
  of crEdnNil, crEdnNumber, crEdnString, crEdnBool, crEdnKeyword, crEdnSymbol:
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
