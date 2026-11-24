/* Checks sh2_divu.h against plain C.  Needs real hardware, an emulator
   with DIVU (Mednafen, MAME) or a GDB SH sim with a DIVU model.
   Exit status 0 and "PASS" when every result matches.  */

#include <stdio.h>
#include <stdint.h>
#include "sh2_divu.h"

static uint32_t seed = 4321;
static uint32_t rnd (void) { seed = seed * 1103515245u + 12345u; return seed ^ (seed >> 16); }

static int fails, sat_fails;
#define CHECK(c, what, i) do { if (!(c)) { if (fails++ < 10) printf ("FAIL %s at %u\n", what, (unsigned) (i)); } } while (0)
/* Overflow results follow Mednafen; reported apart since not guaranteed.  */
#define CHECK_SAT(c, what, i) do { if (!(c)) { if (sat_fails++ < 10) printf ("SATURATION DIFFERS %s at %u\n", what, (unsigned) (i)); } } while (0)

static int32_t pick (void)
{
  static const int32_t ext[] = { INT32_MIN, INT32_MAX, -1, 0, 1, 2, -2, 0x10000, -0x10000, 0x7FFF, -0x8000 };
  uint32_t r = rnd ();
  switch (r & 7)
    {
    case 0: return ext[(r >> 3) % 11];
    case 1: return (int32_t) rnd () >> (rnd () & 31);	/* small magnitudes */
    default: return (int32_t) rnd ();
    }
}

static int32_t sat (int64_t num, int32_t den)
{
  return ((num < 0) != (den < 0)) ? INT32_MIN : INT32_MAX;
}

static void check_64 (int64_t num, int32_t den, int32_t q, int32_t r, const char *what, unsigned i)
{
  if (den != 0)
    {
      int64_t rq = num / den;	/* num is at most 2^47 in magnitude here: no C overflow */
      if (rq > INT32_MIN && rq <= INT32_MAX)
	{
	  CHECK (q == (int32_t) rq && r == (int32_t) (num % den), what, i);
	  CHECK ((SH2_DIVU_DVCR & 1) == 0, "OVF flag set for an in-range divide", i);
	  return;
	}
      /* Mednafen: an exact +2^31 quotient with a negative divisor gives
	 0x80000000 without overflow; -2^31 overflows to 0x80000000.  */
      if (rq == 2147483648LL && den < 0 && num % den == 0)
	{
	  CHECK_SAT (q == INT32_MIN && (SH2_DIVU_DVCR & 1) == 0, what, i);
	  SH2_DIVU_DVCR = 0;
	  return;
	}
    }
  CHECK_SAT (q == sat (num, den) && (SH2_DIVU_DVCR & 1) != 0, what, i);
  SH2_DIVU_DVCR = 0;
}

int main (void)
{
  SH2_DIVU_DVCR = 0;
  for (unsigned i = 0; i < 20000; i++)
    {
      int32_t a = pick (), b = pick ();

      /* 32/32 */
      int32_t q = sh2_div32 (a, b), r = sh2_div_remainder ();
      if (b != 0 && !(a == INT32_MIN && b == -1))
	{
	  CHECK (q == a / b && r == a % b, "div32", i);
	  CHECK ((SH2_DIVU_DVCR & 1) == 0, "OVF flag set for an in-range div32", i);
	}
      else if (b == 0)
	CHECK_SAT (q == (a < 0 ? INT32_MIN : INT32_MAX) && (SH2_DIVU_DVCR & 1) != 0, "div32 by zero", i);
      else
	CHECK_SAT (q == INT32_MIN, "div32 INT32_MIN/-1", i);
      SH2_DIVU_DVCR = 0;

      /* 16.16 */
      q = sh2_fdiv (a, b);
      r = sh2_div_remainder ();
      check_64 ((int64_t) a * 65536, b, q, r, "fdiv", i);

      /* 64/32 with a dividend that usually fits */
      int64_t n = (int64_t) a * (int32_t) (rnd () & 0xFFFF);
      q = sh2_div64_32 (n, b);
      r = sh2_div_remainder ();
      check_64 (n, b, q, r, "div64_32", i);

      /* start, other work, result */
      sh2_fdiv_start (a, b);
      volatile int32_t work = 0;
      for (int k = 0; k < (int) (i & 15); k++)
	work += k * a;
      q = sh2_div_result ();
      r = sh2_div_remainder ();
      check_64 ((int64_t) a * 65536, b, q, r, "fdiv async", i);
    }

  printf ("%s (saturation checks: %s)\n", fails ? "FAILED" : "PASS", sat_fails ? "differ" : "match Mednafen");
  return fails != 0;
}
