
Cirru EDN in Nim
----

> Load Cirru EDN in Nim.

### Usage

```nim
requires "https://github.com/Cirru/cirru-edn.nim#v0.3.8"
```

```nim
import cirru_edn

parseEdnFromStr("do 1") # gets 1
parseEdnFromStr("[] 1 2 3")

crEdn(1)

let x = crEdn(@[1])

echo $x # stringify
```

type detection:

```nim
import cirru_edn

let x = parseEdnFromStr("do 1") # gets 1

case x.kind:
of crEdnNil: # ...
of crEdnBool: # ...
of crEdnNumber: # ...
of crEdnKeyword: # ...
of crEdnString: # ...
of crEdnVector: # ...
of crEdnList: # ...
of crEdnMap: # ...

formatToCirru(x) # returns string
formatToCirru(x, true) # turn on useInline option
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
