import nimsimd/avx
from std/fenv import epsilon

when defined(gcc) or defined(clang):
  {.localPassc: "-mavx".}

# SIMD 64-bit floating point multiplication
let
  eps = epsilon(float64)
  a1 = mm256_set_pd(2.0, 3.0, 4.0, 5.0)
  b1 = mm256_set1_pd(eps)
  c1 = mm256_mul_pd(a1, b1)
  d1 = mm256_set1_pd(2.0)  
  q1 = mm256_div_pd(c1, d1)
  # s1 = mm256_add_pd()

# Cast the vector to echo as separate float32 values
# echo cast[array[4, float32]](c)
echo "epsilon(float64)=", eps
echo cast[array[4, float64]](c1)
echo cast[array[4, float64]](q1)