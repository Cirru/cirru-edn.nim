
Cirru EDN in Nim
----

> Load Cirru EDN in Nim

### Usage

```bash
nimble install cirru-edn # not published yet

# alternatively
nimble install https://github.com/Cirru/cirru-edn.nim
```

```nim
import cirruEdn

parseEdnFromStr("do 1") # gets 1
parseEdnFromStr("[] 1 2 3")

crEdn(1)

let x =crEdn(@[1])

echo $x # stringify
```

type detection:

```nim
import cirruEdn

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
```

### License

MIT
