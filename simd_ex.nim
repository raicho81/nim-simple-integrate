import nimsimd/[sse2, sse3, avx, avx2]
from std/fenv import epsilon
import nimsimd/runtimecheck

import nimsimd/sse42

when defined(gcc) or defined(clang):
  {.localPassc: "-msse4.2".}

# SIMD floating point multiplication
let
  a = mm_set1_ps(1.0) # Vector of 4 float32 each with value 1.0
  b = mm_set1_ps(2.0) # Vector of 4 float32 each with value 2.0
  c = mm_mul_ps(a, b) # SIMD vector multiplication operator

echo checkInstructionSets({SSE41, PCLMULQDQ})

# Cast the vector to echo as separate float32 values
echo cast[array[4, float32]](c)

let four_ones = mm256_set1_pd(1.0);
let four_floats = mm256_set_pd(1.0, 2.0, 3.0, 4.0)
let four_eps = mm256_set1_pd(epsilon(float))