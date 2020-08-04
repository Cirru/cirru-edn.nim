
import unittest

import cirruEdn

test "parse data":
  check parseEdnFromStr("[]") == 1
