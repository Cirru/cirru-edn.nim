
import unittest

import cirruEdn
import cirruEdn/types

test "parse data":
  check parseEdnFromStr("do true") == CirruEdnValue(kind: crEdnBool, boolVal: true)
  check parseEdnFromStr("do false") == CirruEdnValue(kind: crEdnBool, boolVal: false)
  check parseEdnFromStr("do nil") == CirruEdnValue(kind: crEdnNil)

  check parseEdnFromStr("do 1") == CirruEdnValue(kind: crEdnNumber, numberVal: 1)
  check parseEdnFromStr("do |a") == CirruEdnValue(kind: crEdnString, stringVal: "a")
  check parseEdnFromStr("do \"\"a\"") == CirruEdnValue(kind: crEdnString, stringVal: "a")
  check parseEdnFromStr("do :k") == CirruEdnValue(kind: crEdnKeyword, keywordVal: "k")
