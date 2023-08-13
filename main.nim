from std/fenv import epsilon
import std/locks
import strutils

type 
  IntegrandFunction = proc(x: float): float {.nimcall, gcsafe.}               # Derivate of the primitive function

const
  C = 0
  numCpus* {.strdefine.} = "12"

let
  intervals = parseInt(numCpus)
  Derivate = proc(x: float64): float64 = x * x
  PrimitiveFunction = proc(x: float64): float64 = x * x * x / 3 + C # + C which I choose to be zero
  eps = abs(epsilon(float64)*10e2) # 0.00000001

var
  thr: array[0..(parseInt(numCpus) - 1), Thread[tuple[f: IntegrandFunction, intervalStart, intervalEnd: float64, eps: float64]]]
  L: Lock
  sum: float64

sum = 0.0
initLock(L)

proc ThreadFunc(p: tuple[f: IntegrandFunction, intervalStart, intervalEnd: float64, eps: float64]) {.thread.} = 
    echo "Created compute thread for interval: [", p.intervalStart, ", ", p.intervalEnd ,"]"

    let
      endValue = (p.intervalEnd - 2 * p.eps)

    var
      x = (p.intervalStart + p.eps)
      leftSum = p.f(x - p.eps) * p.eps
      rightSum = p.f(x + p.eps) * p.eps
      partialSum = (leftSum + rightSum) / 2                # Error correction

    leftSum = rightSum
    while x <= endValue:
      x = x + p.eps
      rightSum = p.f(x + p.eps) * p.eps      
      partialSum = partialSum + (leftSum + rightSum) / 2                # Error correction
      leftSum = rightSum

    echo "partialSum = ", partialSum
    withLock(L):
      sum = sum + partialSum

var 
    intervalStart = 0.0.float64
    intervalEnd = 1.0.float64
    intervalLen = (intervalEnd - intervalStart) / float64(intervals)

echo "eps = ", eps

for i in 0..high(thr): 
  createThread(thr[i], ThreadFunc, (Derivate, intervalStart, (intervalStart + intervalLen), eps))
  intervalStart = intervalStart + intervalLen
joinThreads(thr)
deinitLock(L)

let computedSpeculativeEpsApproximation = abs(sum - (PrimitiveFunction(intervalEnd) - PrimitiveFunction(intervalStart)))  # Assume C is zero

echo "Integral(", IntegrandFunction, ") = ", sum
echo "computedSpeculativeEpsApproximation = ", computedSpeculativeEpsApproximation

