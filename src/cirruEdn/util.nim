
import sequtils
import sets

import cirruEdn/types

proc map*[T](xs: CirruEdnValue, f: proc (x: CirruEdnValue): T): seq[T] =
  case xs.kind:
  of crEdnList:
    return xs.listVal.map(f)
  of crEdnVector:
    return xs.vectorVal.map(f)
  of crEdnSet:
    var list = newSeq[CirruEdnValue]()
    for x in xs.setVal.items:
      list.add x
    return list.map(f)
  else:
    raise newException(EdnOpError, "map does not work on Cirru EDN literals")

proc mapPairs*[T](xs: CirruEdnValue, f: proc (p: tuple[k: CirruEdnValue, v: CirruEdnValue]): T): seq[T] =
  case xs.kind:
  of crEdnMap:
    var ys: seq[tuple[k:CirruEdnValue, v:CirruEdnValue]] = @[]
    for k, v in xs.mapVal:
      ys.add (k, v)
    return ys.map(f)

  else:
    raise newException(EdnOpError, "map does not work on Cirru EDN literals")
