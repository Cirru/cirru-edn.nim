# Package

version       = "0.1.6"
author        = "jiyinyiyong"
description   = "Cirru EDN loader in Nim"
license       = "MIT"
srcDir        = "src"



# Dependencies

requires "nim >= 1.2.6"
requires "cirru-parser >= 0.0.5"

task t, "Runs the test suite":
  exec "nim c  --hints:off -r tests/testEdn.nim"
