import std/[os, strutils, times, streams]
import msgpack4nim

type
  Sample = object
    id: int
    name: string
    values: seq[int]
    flags: array[4, bool]
    ratio: float64
    meta: tuple[a: int, b: string]

proc buildSample(): Sample =
  result.id = 42
  result.name = "alpha"
  result.values = @[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  result.flags = [true, false, true, false]
  result.ratio = 3.1415926
  result.meta = (a: 7, b: "beta")

template timeIt(label: string, iters: int, body: untyped) =
  let t0 = cpuTime()
  for i in 0..<iters:
    body
  let t1 = cpuTime()
  let elapsed = t1 - t0
  let perOp = (elapsed * 1_000_000_000.0) / float(iters)
  echo label, ": ", elapsed.formatFloat(ffDecimal, 3), "s (", perOp.formatFloat(ffDecimal, 1), " ns/op)"

proc main() =
  let iters = if paramCount() > 0: parseInt(paramStr(1)) else: 100000
  let sample = buildSample()
  let data = pack(sample)

  when defined(msgpack_obj_to_map):
    echo "encoding: map"
  elif defined(msgpack_obj_to_stream):
    echo "encoding: stream"
  else:
    echo "encoding: array"

  var s = MsgStream.init(data)
  var decoded: Sample
  var sink = 0

  timeIt("unpack sample", iters):
    s.setPosition(0)
    s.unpack(decoded)
    sink = sink xor decoded.id

  timeIt("skip sample", iters):
    s.setPosition(0)
    s.skip_msg()
    sink = sink xor int(s.getPosition())

  if sink == 123456789:
    echo "ignore: ", sink

when isMainModule:
  main()
