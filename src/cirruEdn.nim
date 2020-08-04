
import cirruParser
import cirruEdn/types

proc parseEdnFromStr*(code: string): int =
  let tree = parseCirru code
  return 1
