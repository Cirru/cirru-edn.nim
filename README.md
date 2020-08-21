
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
import cirruEdn/gen

parseEdnFromStr("do 1") # gets 1
parseEdnFromStr("[] 1 2 3")

crEdn(1)
crEdn(@[1])
```

type detection... _TODO_

iterator... _TODO_

### License

MIT
