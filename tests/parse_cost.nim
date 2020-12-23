
import nimprof
import cirru_edn

let file = "/Users/chen/repo/cirru/calcit-runner.nim/example/compact.cirru"
# let file = "/Users/chen/repo/cirru/calcit-editor/calcit.cirru"
# let file = "/Users/chen/repo/cirru/bisection-key/calcit.cirru"

echo "start"
discard parseCirruEdn(readFile(file))
echo "finish"
