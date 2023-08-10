import std/math
from std/fenv import epsilon
import std/locks
import psutil

type 
  IntegrandFunction = proc(x: float): float {.nimcall, gcsafe.}               # Derivate of the primitive function

const C = 0

let
    intervals =  cpu_count()
    Derivate = proc(x: float): float = x * x
    PrimitiveFunction = proc(x: float): float = x * x * x / 3 + C # + C which I choose to be zero
    eps = epsilon(float)    # r: 0.00000001 - probably a more sensible value >:)

var
  thr: array[0..11, Thread[tuple[f: IntegrandFunction, intervalStart, intervalEnd: float, eps: float, sum: ref float]]]
  L: Lock
  sum: ref float

new(sum)
sum[] = 0.0
initLock(L)

proc ThreadFunc(p: tuple[f: IntegrandFunction, intervalStart, intervalEnd: float, eps: float, sum: ref float]) {.thread.} = 
    echo "Created compute thread for interval: [", p.intervalStart, ", ", p.intervalEnd ,"]"
    var
      x = p.intervalStart
      value = 0.0
    while x <= (p.intervalEnd - p.eps):
      x = x + eps
      let
        leftSum = p.f(x - p.eps) * p.eps
        rightSum = p.f(x + p.eps) * p.eps
      value = value + (leftSum + rightSum) / 2                # Error correction
    withLock(L):
      p.sum[] = p.sum[] + value

var 
    intervalStart = 0.0
    intervalEnd = 10.0
    intervalLen = (intervalEnd - intervalStart) / float(intervals)

echo "eps = ", eps

for i in 0..high(thr): 
  createThread(thr[i], ThreadFunc, (Derivate, intervalStart, (intervalStart + intervalLen), eps, sum))
  intervalStart = intervalStart + intervalLen
joinThreads(thr)
# deinitLock(L)

let computedSpeculativeEpsApproximation = abs(sum[] - (PrimitiveFunction(10.0) - PrimitiveFunction(0.0)))  # Assume C is zero

echo "computedSpeculativeEpsApproximation = ", computedSpeculativeEpsApproximation

