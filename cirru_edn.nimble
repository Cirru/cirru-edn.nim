# Package

version       = "0.4.10"
author        = "jiyinyiyong"
description   = "Cirru EDN loader in Nim"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.2.6"
requires "cirru_parser >= 0.3.0"
requires "cirru_writer >= 0.1.4"

task t, "Runs the test suite":
  exec "nim c  --hints:off -r tests/test_edn.nim"

task perf, "try large file":
  exec "nim compile --verbosity:0 --profiler:on --stackTrace:on --hints:off -r tests/parse_cost"
