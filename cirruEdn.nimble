# Package

version       = "0.1.0"
author        = "jiyinyiyong"
description   = "Cirru EDN loader in Nim"
license       = "MIT"
srcDir        = "src"



# Dependencies

requires "nim >= 1.2.6"
requires "cirru-parser >= 0.0.5"

task t, "Runs the test suite":
  exec "nim c -r tests/testEdn.nim"
