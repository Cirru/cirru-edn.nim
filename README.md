
Cirru EDN in Nim
----

> Load Cirru EDN in Nim.

### Usage

```nim
requires "https://github.com/Cirru/cirru-edn.nim#v0.4.0"
```

```nim
import cirru_edn

parseCirruEdn("do 1") # gets 1
parseCirruEdn("[] 1 2 3")

let x = genCrEdnList(genCrEdn(1))

echo $x # stringify
```

type detection:

```nim
import cirru_edn

let x = parseCirruEdn("do 1") # gets 1

case x.kind:
of crEdnNil: # ...
of crEdnBool: # ...
of crEdnNumber: # ...
of crEdnKeyword: # ...
of crEdnString: # ...
of crEdnVector: # ...
of crEdnList: # ...
of crEdnMap: # ...
of crEdnRecord: # ...

formatToCirru(x) # returns string
formatToCirru(x, true) # turn on useInline option
```

Functions for generating data:

```nim
genCrEdn()
genCrEdn(true)
genCrEdn(1)
genCrEdn("a")
genCrEdnKeyword("k")
genCrEdnList(genCrEdn(1), genCrEdn(1))
genCrEdnVector(genCrEdn(1), genCrEdn(1))
genCrEdnSet(genCrEdn(1), genCrEdn(2))
genCrEdnMap(genCrEdnKeyword("a"), genCrEdn(2)) # even number of arguments
genCrEdnRecord("Demo", genCrEdn("a"), genCrEdn(2)) # odd number of arguments, string keys
```

### Syntax

Cirru EDN is based on [Cirru Text Syntax](http://text.cirru.org/), on top of that is some syntax for EDN:

- Lists and vectors:

```cirru
[] 1 2 3
```

```cirru
list 1 2 3
```

- HashMaps:

```cirru
{}
  :a 1
  :b 3
```

- Record:

Record name and record fields are represented in symbols:

```cirru
%{} Demo
  a 1
  b 2
```

- Sets:

```cirru
#{} 1 2 3
```

- Literals, since Cirru use lines for expressions, need `do` for extracting a top value:

```cirru
do 1
```

```cirru
do :k
```

```cirru
do nil
```

- Strings, needs to be prefixed with a `|`(or a single escaped `"`):

```cirru
do |short
```

```cirru
do "|long text"
```

- Quoted Cirru code(based on types from [Cirru Parser](https://github.com/Cirru/parser.nim)):

```cirru
{}
  :code $ quote
    def a (x y) (+ x y)
```

### License

MIT
