
import unittest
import strutils
import tables
import sets
import json
import options

import cirru_parser

import cirru_edn

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

test "parse set":
  check parseEdnFromStr("set") == crEdn(HashSet[CirruEdnValue]())
  check parseEdnFromStr("set 1 :a") == crEdn(toHashSet(@[crEdn(1), crEdn("a", true) ]))
  check parseEdnFromStr("#{} 1 :a") == crEdn(toHashSet(@[crEdn(1), crEdn("a", true) ]))

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

test "iterate data in map":
  let t1 = parseEdnFromStr("[] 1 2 3").map(proc(x: CirruEdnValue): float =
    case x.kind:
    of crEdnNumber: x.numberVal
    else: 0
  )
  check (t1 == @[1.0, 2, 3])

  let t2 = parseEdnFromStr("{} (:a 1) (:b 2)").mapPairs(proc(p: tuple[k: CirruEdnValue, v: CirruEdnValue]): float =
    case p.v.kind:
    of crEdnNumber: p.v.numberVal
    else: 0.0
  )
  check (t2 == @[2.0, 1.0])

test "parse large file":
  let content = readFile("tests/compact.cirru")
  let data = parseEdnFromStr(content)
  let generated = $ data # generates simple EDN

  let expected = readFile("tests/compact.edn")
  check (generated == expected)

test "utils":
  let dict = parseEdnFromStr("{} (:a 1)")
  check (dict.contains(crEdn("a", true)) == true)
  check (dict.get(crEdn("a", true)) == crEdn(1))
  check (dict.get(crEdn("b", true)) == crEdn())

test "to json":
  check (%*{"a": [1.0, 2.0]} == toJson(parseEdnFromStr("{} (:a ([] 1 2))")))
  check (toCirruEdn(%*{"a": [1.0, 2.0]}) == parseEdnFromStr("{} (|a ([] 1 2))"))

test "quoted":
  check (parseEdnFromStr("quote $ + 1 2") == CirruEdnValue(kind: crEdnQuotedCirru, quotedVal: parseCirru("+ 1 2").first.get))

let mixedExample = """
{}
  |b $ {} (|c |d)
  |a $ [] 1.0 2.0
"""

let arrayExample = """
[] 1.0
  [] 2.0
    [] 3.0 ([] 4.0) 5.0
    , 6.0
  , 7.0
"""

let quotedExample = """
{} $ :a (quote $ def a 1)
"""

test "write":
  check formatToCirru(toCirruEdn(%*{"a": [1.0, 2.0], "b": {"c": "d"}})).strip == mixedExample.strip
  check formatToCirru(toCirruEdn(%*[1,2, "3", {}])).strip == "[] 1.0 2.0 |3 $ {}"
  check formatToCirru(toCirruEdn(%*[1, [2, [3, [4], 5], 6], 7])).strip == arrayExample.strip
  check formatToCirru(toCirruEdn(%* true)).strip == "do true"
  check formatToCirru(toCirruEdn(%* 1)).strip == "do 1.0"
  check formatToCirru(toCirruEdn(%* "a")).strip == "do |a"
  check formatToCirru(toCirruEdn(%* ":a")).strip == "do |:a"

  check parseEdnFromStr(quotedExample).formatToCirru.strip == quotedExample.strip