/* sh2_divu.h - division through the SH7604 on-chip division unit (DIVU).
   GCC divides with a libgcc call: a 64/32 divide such as 16.16 fixed
   point ((int64_t) a << 16) / b goes through the generic 64-bit
   __divdi3.  DIVU does 32/32 and 64/32 signed divides in 39 cycles, and
   the CPU keeps running until it reads a DIVU register.

   Results:
   - When INT32_MIN < quotient <= INT32_MAX, quotient and remainder are
     exactly C's (truncation toward zero, remainder has the dividend's
     sign).  32/32 divides are always in range, except x / 0 and
     INT32_MIN / -1.
   - Otherwise (division by zero, quotient out of range or exactly
     -2^31 in a 64/32 divide) the result is not reliable: per Mednafen,
     DVCR.OVF is usually set and the quotient saturates to 0x7FFFFFFF or
     0x80000000 by sign (MAME always gives 0x7FFFFFFF), and the
     remainder is undefined.

   Requirements:
   - DVCR.OVFIE (overflow interrupt enable) must be 0, its reset value.
   - DIVU is shared state: an interrupt handler that divides with DIVU
     between a start and its result read corrupts the caller's divide.
     Either do not use DIVU in interrupt handlers or save and restore
     DVSR/DVDNTH/DVDNTL there.  Each CPU (master, slave) has its own
     DIVU.  */

#ifndef SH2_DIVU_H
#define SH2_DIVU_H

#include <stdint.h>

#define SH2_DIVU_DVSR   (*(volatile int32_t *) 0xFFFFFF00)	/* divisor */
#define SH2_DIVU_DVDNT  (*(volatile int32_t *) 0xFFFFFF04)	/* 32/32 dividend: starts */
#define SH2_DIVU_DVCR   (*(volatile uint32_t *) 0xFFFFFF08)	/* bit 0 OVF, bit 1 OVFIE */
#define SH2_DIVU_DVDNTH (*(volatile int32_t *) 0xFFFFFF10)	/* 64/32 dividend high / remainder */
#define SH2_DIVU_DVDNTL (*(volatile int32_t *) 0xFFFFFF14)	/* 64/32 dividend low: starts / quotient */

/* Start a / b (32/32).  */
static inline void
sh2_div32_start (int32_t a, int32_t b)
{
  SH2_DIVU_DVSR = b;
  SH2_DIVU_DVDNT = a;
}

/* Start (a << 16) / b: 16.16 fixed-point divide (64/32).  */
static inline void
sh2_fdiv_start (int32_t a, int32_t b)
{
  SH2_DIVU_DVSR = b;
  SH2_DIVU_DVDNTH = a >> 16;
  SH2_DIVU_DVDNTL = (int32_t) ((uint32_t) a << 16);
}

/* Start a / b with a 64-bit dividend.  */
static inline void
sh2_div64_start (int64_t a, int32_t b)
{
  SH2_DIVU_DVSR = b;
  SH2_DIVU_DVDNTH = (int32_t) (a >> 32);
  SH2_DIVU_DVDNTL = (int32_t) a;
}

/* Quotient of the last divide started; waits for it to finish.  */
static inline int32_t
sh2_div_result (void)
{
  return SH2_DIVU_DVDNTL;
}

/* Remainder of the last divide started; waits for it to finish.  */
static inline int32_t
sh2_div_remainder (void)
{
  return SH2_DIVU_DVDNTH;
}

/* a / b.  */
static inline int32_t
sh2_div32 (int32_t a, int32_t b)
{
  sh2_div32_start (a, b);
  return sh2_div_result ();
}

/* ((int64_t) a << 16) / b: 16.16 fixed-point divide.  */
static inline int32_t
sh2_fdiv (int32_t a, int32_t b)
{
  sh2_fdiv_start (a, b);
  return sh2_div_result ();
}

/* a / b, 64-bit dividend, 32-bit quotient.  */
static inline int32_t
sh2_div64_32 (int64_t a, int32_t b)
{
  sh2_div64_start (a, b);
  return sh2_div_result ();
}

#endif /* SH2_DIVU_H */
