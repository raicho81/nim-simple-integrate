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
    eps = abs(epsilon(float)*10e4) # 0.00000001

var
  thr: array[0..11, Thread[tuple[f: IntegrandFunction, intervalStart, intervalEnd: float, eps: float]]]
  L: Lock
  sum: float64

sum = 0.0
initLock(L)

proc ThreadFunc(p: tuple[f: IntegrandFunction, intervalStart, intervalEnd: float, eps: float]) {.thread.} = 
    echo "Created compute thread for interval: [", p.intervalStart, ", ", p.intervalEnd ,"]"
    var
      x = p.intervalStart
      partialSum = 0.0
    let endValue = (p.intervalEnd - p.eps)
    while x <= endValue:
      x = x + p.eps
      let
        leftSum = p.f(x - p.eps) * p.eps
        rightSum = p.f(x + p.eps) * p.eps
      partialSum = partialSum + (leftSum + rightSum) / 2                # Error correction
    echo "partialSum = ", partialSum
    withLock(L):
      sum = sum + partialSum

var 
    intervalStart = 0.0
    intervalEnd = 10.0
    intervalLen = (intervalEnd - intervalStart) / float(intervals)

echo "eps = ", eps

for i in 0..high(thr): 
  createThread(thr[i], ThreadFunc, (Derivate, intervalStart, (intervalStart + intervalLen), eps))
  intervalStart = intervalStart + intervalLen
joinThreads(thr)
deinitLock(L)

let computedSpeculativeEpsApproximation = abs(sum - (PrimitiveFunction(10.0) - PrimitiveFunction(0.0)))  # Assume C is zero

echo "Integral(", IntegrandFunction, ") = ", sum
echo "computedSpeculativeEpsApproximation = ", computedSpeculativeEpsApproximation

