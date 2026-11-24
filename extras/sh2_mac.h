/* sh2_mac.h - multiply-accumulate (mac.l / mac.w) helpers for the SH-2.
   GCC never emits mac.l or mac.w; these wrap them in inline asm.

   Fixed point is 16.16 in an int32_t (SGL's FIXED); *_fx functions
   return (sum of products) >> 16, truncated to 32 bits.

   Requirements:
   - SR.S must be 0 (the reset value used by GCC code): with S=1 the
     MAC unit saturates and every result here is wrong.
   - int32_t operands 4-byte aligned, int16_t operands 2-byte aligned
     (an unaligned mac.l / mac.w raises an address error).
   - MACH/MACL are clobbered; interrupt handlers that use them must save
     them (GCC's interrupt_handler attribute does).  */

#ifndef SH2_MAC_H
#define SH2_MAC_H

#include <stdint.h>

/* Sum of a[i]*b[i] over 3 elements, >> 16.  */
static inline int32_t
sh2_dot3_fx (const int32_t *a, const int32_t *b)
{
  int32_t hi, lo;
  __asm__ ("clrmac\n\t"
	   "mac.l	@%0+,@%1+\n\t"
	   "mac.l	@%0+,@%1+\n\t"
	   "mac.l	@%0+,@%1+\n\t"
	   "sts	mach,%2\n\t"
	   "sts	macl,%3\n\t"
	   "xtrct	%2,%3"
	   : "+r" (a), "+r" (b), "=r" (hi), "=r" (lo)
	   : "m" (*(const int32_t (*)[3]) a), "m" (*(const int32_t (*)[3]) b)
	   : "mach", "macl");
  return lo;
}

/* Sum of a[i]*b[i] over 4 elements, >> 16.  */
static inline int32_t
sh2_dot4_fx (const int32_t *a, const int32_t *b)
{
  int32_t hi, lo;
  __asm__ ("clrmac\n\t"
	   "mac.l	@%0+,@%1+\n\t"
	   "mac.l	@%0+,@%1+\n\t"
	   "mac.l	@%0+,@%1+\n\t"
	   "mac.l	@%0+,@%1+\n\t"
	   "sts	mach,%2\n\t"
	   "sts	macl,%3\n\t"
	   "xtrct	%2,%3"
	   : "+r" (a), "+r" (b), "=r" (hi), "=r" (lo)
	   : "m" (*(const int32_t (*)[4]) a), "m" (*(const int32_t (*)[4]) b)
	   : "mach", "macl");
  return lo;
}

/* Full 64-bit sum of a[i]*b[i] for i < n.  */
static inline int64_t
sh2_dot_l (const int32_t *a, const int32_t *b, uint32_t n)
{
  uint32_t hi, lo;
  if (n == 0)
    return 0;
  __asm__ ("clrmac\n"
	   "1:\tmac.l	@%0+,@%1+\n\t"
	   "dt	%2\n\t"
	   "bf	1b\n\t"
	   "sts	mach,%3\n\t"
	   "sts	macl,%4"
	   : "+r" (a), "+r" (b), "+r" (n), "=r" (hi), "=r" (lo)
	   : : "mach", "macl", "t", "memory");
  return (int64_t) (((uint64_t) hi << 32) | lo);
}

/* Sum of a[i]*b[i] for i < n, >> 16.  */
static inline int32_t
sh2_dot_fx (const int32_t *a, const int32_t *b, uint32_t n)
{
  int32_t hi, lo;
  if (n == 0)
    return 0;
  __asm__ ("clrmac\n"
	   "1:\tmac.l	@%0+,@%1+\n\t"
	   "dt	%2\n\t"
	   "bf	1b\n\t"
	   "sts	mach,%3\n\t"
	   "sts	macl,%4\n\t"
	   "xtrct	%3,%4"
	   : "+r" (a), "+r" (b), "+r" (n), "=r" (hi), "=r" (lo)
	   : : "mach", "macl", "t", "memory");
  return lo;
}

/* Full 64-bit sum of a[i]*b[i] (16-bit operands) for i < n.  */
static inline int64_t
sh2_dot_w (const int16_t *a, const int16_t *b, uint32_t n)
{
  uint32_t hi, lo;
  if (n == 0)
    return 0;
  __asm__ ("clrmac\n"
	   "1:\tmac.w	@%0+,@%1+\n\t"
	   "dt	%2\n\t"
	   "bf	1b\n\t"
	   "sts	mach,%3\n\t"
	   "sts	macl,%4"
	   : "+r" (a), "+r" (b), "+r" (n), "=r" (hi), "=r" (lo)
	   : : "mach", "macl", "t", "memory");
  return (int64_t) (((uint64_t) hi << 32) | lo);
}

/* out = m * v, m a row-major 3x3 fixed matrix.  out may alias v.  */
static inline void
sh2_mat3_vec3_fx (const int32_t *m, const int32_t *v, int32_t *out)
{
  int32_t x = sh2_dot3_fx (m, v);
  int32_t y = sh2_dot3_fx (m + 3, v);
  int32_t z = sh2_dot3_fx (m + 6, v);
  out[0] = x;
  out[1] = y;
  out[2] = z;
}

#endif /* SH2_MAC_H */
