/* Checks sh2_mac.h against plain C on the GDB SH simulator.
   Build: sh2eb-elf-gcc -m2 -O2 test_sh2_mac.c <syscall stubs> -o t.elf; run t.elf
   Exit status 0 and "PASS" when every result matches.  */

#include <stdio.h>
#include <stdint.h>
#include "sh2_mac.h"

static uint32_t seed = 12345;
static uint32_t rnd (void) { seed = seed * 1103515245u + 12345u; return seed ^ (seed >> 16); }

static int64_t ref_l (const int32_t *a, const int32_t *b, uint32_t n)
{ uint64_t s = 0; for (uint32_t i = 0; i < n; i++) s += (uint64_t) ((int64_t) a[i] * b[i]); return (int64_t) s; }
static int64_t ref_w (const int16_t *a, const int16_t *b, uint32_t n)
{ int64_t s = 0; for (uint32_t i = 0; i < n; i++) s += (int32_t) a[i] * b[i]; return s; }
static int32_t fx (int64_t s) { return (int32_t) (uint32_t) ((uint64_t) s >> 16); }

static int fails;
#define CHECK(c, what, i) do { if (!(c)) { if (fails++ < 10) printf ("FAIL %s at %u\n", what, (unsigned) (i)); } } while (0)

#define N 40
static int32_t la[N], lb[N];
static int16_t wa[N], wb[N];

static int32_t pick32 (void)
{
  static const int32_t ext[] = { INT32_MIN, INT32_MAX, -1, 0, 1, 0x10000, -0x10000 };
  uint32_t r = rnd ();
  return (r & 7) == 0 ? ext[(r >> 3) % 7] : (int32_t) rnd ();
}

static int16_t pick16 (void)
{
  static const int16_t ext[] = { INT16_MIN, INT16_MAX, -1, 0, 1 };
  uint32_t r = rnd ();
  return (r & 7) == 0 ? ext[(r >> 3) % 5] : (int16_t) rnd ();
}

int main (void)
{
  for (unsigned iter = 0; iter < 2000; iter++)
    {
      for (int i = 0; i < N; i++)
	{ la[i] = pick32 (); lb[i] = pick32 (); wa[i] = pick16 (); wb[i] = pick16 (); }
      uint32_t n = iter % (N + 1);

      CHECK (sh2_dot3_fx (la, lb) == fx (ref_l (la, lb, 3)), "dot3_fx", iter);
      CHECK (sh2_dot4_fx (la, lb) == fx (ref_l (la, lb, 4)), "dot4_fx", iter);
      CHECK (sh2_dot_l (la, lb, n) == ref_l (la, lb, n), "dot_l", iter);
      CHECK (sh2_dot_fx (la, lb, n) == fx (ref_l (la, lb, n)), "dot_fx", iter);
      CHECK (sh2_dot_w (wa, wb, n) == ref_w (wa, wb, n), "dot_w", iter);

      int32_t out[3], v[3] = { lb[0], lb[1], lb[2] };
      sh2_mat3_vec3_fx (la, v, out);
      for (int r = 0; r < 3; r++)
	CHECK (out[r] == fx (ref_l (la + 3 * r, v, 3)), "mat3_vec3_fx", iter);
      sh2_mat3_vec3_fx (la, v, v);	/* out aliasing v */
      for (int r = 0; r < 3; r++)
	CHECK (v[r] == out[r], "mat3_vec3_fx alias", iter);
    }

  /* All-extreme sums: 40 * INT32_MIN^2 overflows 64 bits' sign range?  No:
     40 * 2^62 wraps, which mac.l (S=0) and the reference both do mod 2^64.  */
  for (int i = 0; i < N; i++)
    { la[i] = INT32_MIN; lb[i] = INT32_MIN; wa[i] = INT16_MIN; wb[i] = INT16_MIN; }
  CHECK (sh2_dot_l (la, lb, N) == ref_l (la, lb, N), "dot_l extreme", 0);
  CHECK (sh2_dot_w (wa, wb, N) == ref_w (wa, wb, N), "dot_w extreme (> 32 bits)", 0);

  puts (fails ? "FAILED" : "PASS");
  return fails != 0;
}
