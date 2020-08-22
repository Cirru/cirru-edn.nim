
import unittest
import tables

import cirruEdn
import cirruEdn/types
import cirruEdn/format
import cirruEdn/gen

test "data gen":
  check crEdn(true) == CirruEdnValue(kind: crEdnBool, boolVal: true)
  check crEdn(false) == CirruEdnValue(kind: crEdnBool, boolVal: false)
  check crEdn() == CirruEdnValue(kind: crEdnNil)
  check crEdn(1) == CirruEdnValue(kind: crEdnNumber, numberVal: 1)
  check crEdn("a") == CirruEdnValue(kind: crEdnString, stringVal: "a")
  check crEdn("a", true) == CirruEdnValue(kind: crEdnKeyword, keywordVal: "a")
  check crEdn(@[crEdn(1)]) == CirruEdnValue(kind: crEdnVector, vectorVal: @[ crEdn(1) ])
  check crEdn(@[crEdn(@[])]) == CirruEdnValue(kind: crEdnVector, vectorVal: @[ crEdn(@[]) ])
  check crEdn(@[crEdn(1)], true) == CirruEdnValue(kind: crEdnList, listVal: @[ crEdn(1) ])


test "gen table":
  var unitTable = initTable[CirruEdnValue, CirruEdnValue]()
  unitTable[crEdn(1)] = crEdn(2)
  check crEdn(unitTable) == CirruEdnValue(kind: crEdnMap, mapVal: unitTable)

test "parse literals":
  check parseEdnFromStr("do true") == crEdn(true)
  check parseEdnFromStr("do false") == crEdn(false)
  check parseEdnFromStr("do nil") == crEdn()

  check parseEdnFromStr("do 1") == crEdn(1)
  check parseEdnFromStr("do |a") == crEdn("a")
  check parseEdnFromStr("do \"\\\"a\"") == crEdn("a")
  check parseEdnFromStr("do :k") == crEdn("k", true)

test "parse vector":
  check parseEdnFromStr("[]") == crEdn(@[])
  check parseEdnFromStr("list") == crEdn(@[], true)
  check parseEdnFromStr("[] 1") == crEdn(@[ crEdn(1) ])
  check parseEdnFromStr("[] $ []") == crEdn(@[ crEdn(@[]) ])

  var t = initTable[CirruEdnValue, CirruEdnValue]()
  check parseEdnFromStr("[] $ {}") == crEdn(@[ crEdn(t) ])

test "parse map":
  var t = initTable[CirruEdnValue, CirruEdnValue]()
  check parseEdnFromStr("{}") == crEdn(t)
  t[crEdn("k", true)] = crEdn("v")
  check parseEdnFromStr("{} (:k |v)") == crEdn(t)
  t[crEdn("arr", true)] = crEdn(@[crEdn(1), crEdn(2), crEdn(3)])
  check parseEdnFromStr("{} (:k |v) (:arr $ [] 1 2 3)") == crEdn(t)

test "iterable":
  let vectorData = parseEdnFromStr("[] 1 2 3 4")
  var counted: int = 0
  for i in vectorData:
    counted = counted + 1
  check (counted == 4)

  let listData = parseEdnFromStr("list 1 2 3 4")
  var counted2: int = 0
  for i in listData:
    counted2 = counted2 + 1
  check (counted2 == 4)

  let mapData = parseEdnFromStr("{} (:a 1) (:b 2)")
  var counted3 = 0
  for k, v in mapData:
    counted3 = counted3 + 1
  check (counted3 == 2)