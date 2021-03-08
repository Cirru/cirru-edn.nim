
import unittest
import strutils
import tables
import sets
import json
import options

import cirru_parser

import cirru_edn

test "data gen":
  check genCrEdn(true) == CirruEdnValue(kind: crEdnBool, boolVal: true)
  check genCrEdn(false) == CirruEdnValue(kind: crEdnBool, boolVal: false)
  check genCrEdn() == CirruEdnValue(kind: crEdnNil)
  check genCrEdn(1) == CirruEdnValue(kind: crEdnNumber, numberVal: 1)
  check genCrEdn("a") == CirruEdnValue(kind: crEdnString, stringVal: "a")
  check genCrEdnKeyword("a") == CirruEdnValue(kind: crEdnKeyword, keywordVal: "a")
  check genCrEdnSymbol("a") == CirruEdnValue(kind: crEdnSymbol, symbolVal: "a")
  check genCrEdnVector(genCrEdn(1)) == CirruEdnValue(kind: crEdnVector, vectorVal: @[ CirruEdnValue(kind: crEdnNumber, numberVal: 1) ])
  check genCrEdnVector(genCrEdnVector()) == CirruEdnValue(kind: crEdnVector, vectorVal: @[CirruEdnValue(kind: crEdnVector, vectorVal: @[])])
  check genCrEdnList(genCrEdn(1)) == CirruEdnValue(kind: crEdnList, listVal: @[ CirruEdnValue(kind: crEdnNumber, numberVal: 1) ])


test "gen table":
  check genCrEdnMap() == CirruEdnValue(kind: crEdnMap, mapVal: initTable[CirruEdnValue, CirruEdnValue]())

test "parse literals":
  check parseCirruEdn("do true") == genCrEdn(true)
  check parseCirruEdn("do false") == genCrEdn(false)
  check parseCirruEdn("do nil") == genCrEdn()

  check parseCirruEdn("do 1") == genCrEdn(1)
  check parseCirruEdn("do |a") == genCrEdn("a")
  check parseCirruEdn("do \"\\\"a\"") == genCrEdn("a")
  check parseCirruEdn("do :k") == genCrEdnKeyword("k")

  check parseCirruEdn("do 'a") == genCrEdnSymbol("a")

test "parse vector":
  check parseCirruEdn("[]") == genCrEdnVector()
  check parseCirruEdn("list") == genCrEdnList()
  check parseCirruEdn("[] 1") == genCrEdnVector( genCrEdn(1) )
  check parseCirruEdn("[] $ []") == genCrEdnVector( genCrEdnVector() )

  var t = initTable[CirruEdnValue, CirruEdnValue]()
  check parseCirruEdn("[] $ {}") == genCrEdnVector( genCrEdnMap() )

test "parse map":
  check parseCirruEdn("{}") == genCrEdnMap()
  check parseCirruEdn("{} (:k |v)") == genCrEdnMap(genCrEdnKeyword("k"), genCrEdn("v"))
  check parseCirruEdn("{} (:k |v) (:arr $ [] 1 2 3)") ==
    genCrEdnMap(genCrEdnKeyword("k"), genCrEdn("v"),
                genCrEdnKeyword("arr"), genCrEdnVector(genCrEdn(1), genCrEdn(2), genCrEdn(3)))

test "parse set":
  check parseCirruEdn("set") == genCrEdnSet()
  check parseCirruEdn("set 1 :a") == genCrEdnSet(genCrEdn(1), genCrEdnKeyword("a"))
  check parseCirruEdn("#{} 1 :a") == genCrEdnSet(genCrEdn(1), genCrEdnKeyword("a"))

test "parse record":
  check parseCirruEdn("%{} Cat (color :red) (weight 100)") ==
    genCrEdnRecord("Cat", genCrEdn("color"), genCrEdnKeyword("red"),
                    genCrEdn("weight"), genCrEdn(100))

test "iterable":
  let vectorData = parseCirruEdn("[] 1 2 3 4")
  var counted: int = 0
  for i in vectorData:
    counted = counted + 1
  check (counted == 4)

  let listData = parseCirruEdn("list 1 2 3 4")
  var counted2: int = 0
  for i in listData:
    counted2 = counted2 + 1
  check (counted2 == 4)

  let mapData = parseCirruEdn("{} (:a 1) (:b 2)")
  var counted3 = 0
  for k, v in mapData:
    counted3 = counted3 + 1
  check (counted3 == 2)

test "iterate data in map":
  let t1 = parseCirruEdn("[] 1 2 3").map(proc(x: CirruEdnValue): float =
    case x.kind:
    of crEdnNumber: x.numberVal
    else: 0
  )
  check (t1 == @[1.0, 2, 3])

  let t2 = parseCirruEdn("{} (:a 1) (:b 2)").mapPairs(proc(p: tuple[k: CirruEdnValue, v: CirruEdnValue]): float =
    case p.v.kind:
    of crEdnNumber: p.v.numberVal
    else: 0.0
  )
  check (t2 == @[2.0, 1.0])

test "parse large file":
  let content = readFile("tests/compact.cirru")
  let data = parseCirruEdn(content)
  let generated = $ data # generates simple EDN

  let expected = readFile("tests/compact.edn")
  check (generated == expected)

test "utils":
  let dict = parseCirruEdn("{} (:a 1)")
  check (dict.contains(genCrEdnKeyword("a")) == true)
  check (dict.get(genCrEdnKeyword("a")) == genCrEdn(1))
  check (dict.get(genCrEdnKeyword("b")) == genCrEdn())

test "to json":
  check (%*{"a": [1.0, 2.0]} == toJson(parseCirruEdn("{} (:a ([] 1 2))")))
  check (toCirruEdn(%*{"a": [1.0, 2.0]}) == parseCirruEdn("{} (|a ([] 1 2))"))

test "quoted":
  check (parseCirruEdn("quote $ + 1 2") == CirruEdnValue(kind: crEdnQuotedCirru, quotedVal: parseCirru("+ 1 2").first.get))

let mixedExample = """
{}
  |b $ {} (|c |d)
  |a $ [] 1 2
"""

let arrayExample = """
[] 1
  [] 2
    [] 3 ([] 4) 5
    , 6
  , 7
"""

let quotedExample = """
{} $ :a
  quote $ def a 1
"""

let stringExample = """
{} ("|some chars:,$()\"aaa" "|with |() a")
  |simple |simple
"""

test "write":
  check formatToCirru(toCirruEdn(%*{"a": [1.0, 2.0], "b": {"c": "d"}})).strip == mixedExample.strip
  check formatToCirru(toCirruEdn(%*[1,2, "3", {}])).strip == "[] 1 2 |3 $ {}"
  check formatToCirru(toCirruEdn(%*[1, [2, [3, [4], 5], 6], 7])).strip == arrayExample.strip
  check formatToCirru(toCirruEdn(%* true)).strip == "do true"
  check formatToCirru(toCirruEdn(%* 1)).strip == "do 1"
  check formatToCirru(toCirruEdn(%* "a")).strip == "do |a"
  check formatToCirru(toCirruEdn(%* ":a")).strip == "do |:a"
  check formatToCirru(genCrEdnList(CirruEdnValue(kind: crEdnSymbol, symbolVal: "a"))).strip == "list 'a"

  check parseCirruEdn(quotedExample).formatToCirru.strip == quotedExample.strip

  check formatToCirru(toCirruEdn(%*{"some chars:,$()\"aaa": "with |() a", "simple": "simple"})).strip == stringExample.strip

let recordExample = """
%{} Cat (color :red)
  weight 100
"""

let recordExample2 = """
%{} Cat (color :red)
  owner $ %{} Person (:age 20)
    :name |Chen
  weight 100
"""

test "write record":
  let c0 = genCrEdnRecord("Cat", genCrEdn("color"), genCrEdnKeyword("red"),
                            genCrEdn("weight"), genCrEdn(100))
  check formatToCirru(c0).strip == recordExample.strip

  check formatToCirru(parseCirruEdn(recordExample2)).strip == recordExample2.strip
