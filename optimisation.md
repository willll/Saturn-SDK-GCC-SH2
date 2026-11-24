# Optimisation work for Saturn (SH-2) binaries

Everything tried in November 2026 to get faster and smaller code from
this toolchain for the Saturn's SH7604 (`sh-elf -m2`): what was applied,
what was rejected, and the measured results.

All measurements use GCC 14.3 with this repository's patches, newlib
4.4.0 and the GDB SH simulator (`run -v` cycle counts), unless noted.
The simulator does not model the Saturn's bus contention or wait states,
so cycle counts are relative indications, not real-hardware timings.

## Summary

| # | Optimisation | Status | Result |
|---|---|---|---|
| 1 | ivopts: post-increment loads (PR113779) | Applied, GCC patch 0001 | Pointer loops use `mov.l @rN+` instead of 4 instructions per load |
| 2 | postreload: fold add into load (PR52049) | Applied up to 14.x, patch 0002 | `add #12,r1; mov.l @r1,r1` becomes `mov.l @(12,r1),r1`; not needed from GCC 15 |
| 3 | auto-inc-dec: increment chains (PR50749) | Applied, patch 0003 | One instruction less per consecutive access; pre-decrement chains on 14.3 only |
| 4 | libgcc soft-float: fp-bit → soft-fp | Applied on 14.3, patch 0004 | Float/double ops 1.4×–3.3× faster, exact rounding; +1.5 to +9.6 KB |
| 5 | Section-built newlib + libgcc | Applied on 14.3 | −9% to −27% `.text` with `--gc-sections` |
| 6 | Linker relaxation (`-mrelax`) | Fixed in binutils, opt-in | Was miscompiling; now correct; saves 0.2–0.7% `.text` |
| 7 | Link-time optimisation (`-flto`) | Rejected | 0 to −0.65% `.text`, no speed change |
| 8 | Globals through GBR | Usable by hand, no patch | Halves global access cost; not available in SGL projects |
| 9 | Fixed-point multiply (`dmuls.l` + `xtrct`) | Nothing to do | GCC already emits the optimal sequence |
| 10 | `mac.l` / `mac.w` multiply-accumulate | Header `extras/sh2_mac.h` | 3×3 matrix × vector 2× faster, 45% smaller |
| 11 | First scheduling pass (sched1) on SH-2 | Rejected | 1–3% slower, 1–2% bigger, register-allocation failures |
| 12 | LRA register allocator (`-mlra`) | Not adopted | Mixed: −1.7% to +1.4% cycles |
| 13 | Fixed-point divide with the SH7604 divider (DIVU) | Not done | Analysed only; SaturnMath++ already does it |
| 14 | Section anchors for globals | Not done | Analysed only; small expected gain |
| 15 | `-mdiv=call-table` division | Not possible | Needs SH-3 shift instructions |

## Applied

### 1. ivopts: post-increment loads (PR113779)

ivopts treated `iv += step; *(iv - step)` as a free post-increment, but
`iv - step` is not a valid SH address, so the auto-increment never
formed. Simple pointer loops used four instructions per load
(`add / mov / add #-64 / mov.l @(60,rN)`) instead of `mov.l @rN+`. The
patch only grants the post-increment cost when the address is valid.

- Patch: `patches/gcc/<version>/0001-ivopts-autoinc-needs-legitimate-offset-PR113779.patch`
- Branches: 8.4, 9.5, 10.4, 11.5, 12.4, 13.3, 14.2, 14.3, 15.3, 16.1, 16.2.
- Tests: torture execute at -O1/-O2/-O3/-Os, no new failures, no ICEs.
  On 15.3, patches 0001 + 0003 together remove 0.06% of instructions at
  -O2.

### 2. postreload: fold an add into the last load (PR52049)

`add #12,r1; mov.l @r1,r1` becomes `mov.l @(12,r1),r1`.

- Patch: `0002-postreload-fold-add-into-last-load-PR52049.patch`
- Branches: 8.4 to 14.3.
- Not ported to GCC 15 and 16: their new late_combine pass already does
  this, and the patch changes zero torture outputs there.

### 3. auto-inc-dec: increment chains (PR50749)

Loops reading consecutive values (`@r4 / @(4,r4) / @(8,r4) / add #12,r4`)
become `@r4+ / @r4+ / @r4+`, one instruction less per iteration. On
14.3 the patch also handles pre-decrement store chains (`*--p = x`),
increments into another register, and negative displacements.

- Patch: `0003-auto-inc-dec-post-increment-chains-PR50749.patch`
- Branches: same as 0001. The extended version (pre-decrement chains)
  is on 14.3 only.
- Tests: torture execute at -O1/-O2/-O3/-Os, with `-funroll-loops` and
  `-g`; no result changed, no ICEs, no `-fcompare-debug` failures, no
  file grows.
- Still open: loops storing backwards several times per iteration
  (`pr50749-qihisi-predec-4.c`) need ivopts to rebase the induction
  variable.

### 4. libgcc soft-float: fp-bit → soft-fp

libgcc's float and double routines switch from the old generic fp-bit to
soft-fp, with an SH-specific `sfp-machine.h` (uses `dmulu.l` and
`__udiv_qrnnd_16`).

| Operation | Speed-up |
|---|---|
| float add / mul | 1.5× |
| float div | 2.1× |
| double add | 1.7× |
| double mul | 1.5× |
| double div | 2.7× (1049 → 391 cycles) |
| compares | 2.2–2.4× |
| conversions | 1.4–3.3× |

- Accuracy: 688,846 random and special-case results match an x86-64 host
  bit for bit; fp-bit rounds some denormal results one ulp off.
- Cost: +1.5 KB `.text` for a program using float add, mul and compare;
  +9.6 KB for one using every operation.
- Patch: `patches/gcc/14.3.0/0004-libgcc-sh-use-soft-fp-instead-of-fp-bit.patch`
  (14.3 only).

### 5. Section-built newlib and libgcc

newlib and libgcc are built with `-ffunction-sections -fdata-sections`
(through `CFLAGS_FOR_TARGET`), so a program linked with
`-Wl,--gc-sections` drops the library code it does not use.

| Program | Program flags only | + section-built libraries |
|---|---|---|
| zlib round trip | −9.4% `.text` | −13.4% |
| printf "hello" | −1.9% | −26.6% (9460 → 6948 bytes) |
| float test | −0.6% | −8.3% |

Output and cycle counts are unchanged. Programs linked without
`--gc-sections` are unaffected. Custom Saturn linker scripts need
`KEEP()` around vectors and the entry point when using `--gc-sections`.

- Commit: `3a6b450` (14.3 only).
- Also found: `build-newlib.sh` exported `newlib_cflags`, which newlib's
  `configure.host` resets, so it never applied. It was removed;
  `--enable-target-optspace` already gives `-Os`.

### 6. Linker relaxation (`-mrelax`): fixed, left opt-in

With stock binutils, `-mrelax` produced broken programs: zlib crashed
(`inflate.c`) or hung (`trees.c`), and libgcc's `lib1funcs.S` did not
assemble. Two binutils patches fix it:

- **0001 (gas):** jump tables stored as zeros, or not adjusted when ld
  removed bytes; `bra`/`bsr`/`bt`/`bf`, PC-relative loads and `mova` to a
  global symbol in the same section got a wrong target.
- **0002 (ld):** a `bsr` landing inside its target after a later
  deletion, jump tables off by 2 bytes at an alignment, swapped
  `R_SH_USES` loads, and calls to static functions in another section
  never relaxed.

Tests, for every binutils version used (2.34, 2.36.1, 2.41, 2.42, 2.43,
2.44): torture execute results identical test by test with and without
`-mrelax` at -O1/-O2/-O3/-Os, and with function sections + `--gc-sections`
at -O2/-Os; targeted checks (global-symbol branches, `lib1funcs.S`,
relaxation across a `mova`) pass, and fail with stock binutils.

- Gain: 0.2–0.7% `.text`, which is why `-mrelax` is not turned on in the
  build.
- Patches: `patches/binutils/<version>/` on every maintained branch.

## Rejected or not needed

### 7. Link-time optimisation (`-flto`)

- With section-built libraries and `--gc-sections`: 0 to −0.65% `.text`
  (zlib -O2: 47092 → 46784 bytes); cycles unchanged. Alone: ±0.1%.
- The toolchain does LTO without the linker plugin (its `ld` is static),
  so LTO objects inside `.a` archives are not optimised. A GCC configured
  with plugin support crashes the static `ld` unless
  `-fno-use-linker-plugin` is passed.
- Verdict: not worth it.

### 8. Globals through GBR

Grouping globals in a struct addressed through GBR
(`#define G ((struct area *) __builtin_thread_pointer())`) works today
with no patch: `mov.x @(disp,GBR)` via R0, reaching 255/510/1020 bytes
for byte/word/long.

- Measured: `frame++` 16 → 8 bytes, `flags |= 4` 16 → 8 bytes, two reads
  20 → 10 bytes, no literal-pool entries.
- SGL owns GBR (`SGL_Start` loads it; about 917 GBR-relative accesses in
  `LIBSGL.A`), so this is unavailable in SGL/SaturnRingLib projects.
- Automatic per-variable small data through GBR would need both a GCC
  patch and a new ELF relocation in binutils: not done.

### 9. Fixed-point multiply

`(int)(((long long)a * b) >> 16)` already compiles to the optimal
`dmuls.l` / `sts macl` / `sts mach` / `xtrct` at -O2 and -Os (`dmulu.l`
for unsigned; `>> 32` gives `dmuls.l` + `sts mach`). No patch needed.

### 10. `mac.l` / `mac.w` multiply-accumulate

GCC never emits `mac.l`/`mac.w`. Making it do so automatically was
estimated at 2–4 weeks: a 64-bit MACH:MACL accumulator in the register
allocator, a new pass to form instructions with two auto-incremented
memory operands, and the SR.S saturation bit. Rejected in favour of an
inline-asm header.

- `extras/sh2_mac.h` (C): `sh2_dot3_fx`, `sh2_dot4_fx`, `sh2_dot_fx`,
  `sh2_dot_l`, `sh2_dot_w` (16-bit), `sh2_mat3_vec3_fx`.
- Test `extras/test_sh2_mac.c`: matches a C reference over 2,000 random
  rounds and extreme values at -O0/-O1/-O2/-O3/-Os; deliberately broken
  copies of the header fail it.
- Gain on a 3×3 matrix × vector: 67 → 33 cycles, 152 → 84 bytes.
- Requirements: SR.S = 0; operands 4-byte (`int32_t`) or 2-byte
  (`int16_t`) aligned.
- SaturnMath++ (C++23) already does the same with `mac.l` in
  `Vector3::Dot` and its matrix code; the header is for C projects.

### 11. First scheduling pass (sched1) on SH-2

The SH backend forces sched1 off below SH-4 (`sh.cc`, citing R0 spill
failures). A test cc1 honouring `-fschedule-insns` was built and
measured.

- Torture execute at -O1/-O2/-O3/-Os: no new failures or ICEs, with or
  without `-fsched-pressure` and `-mlra`.
- zlib `trees.c` at -O3 with `-mlra -fschedule-insns`: "unable to find a
  register to spill", the R0 problem the backend comment warns about.

| -O2 | zlib | fx3d (fixed-point transform) | misc (game logic) |
|---|---|---|---|
| `-fschedule-insns` | +1.2% cycles, +2.0% `.text` | +2.5% | −1.0% |
| `-fschedule-insns -fsched-pressure` | +2.3%, +1.1% `.text` | +1.0% | −0.6% |
| `-mlra -fschedule-insns` | +2.1%, +2.6% `.text` | +2.2% | −0.1% |

- At -Os the pattern is the same (fx3d +2.8%).
- Verdict: slower and bigger; the backend's choice is right. Nothing
  committed.

### 12. LRA register allocator (`-mlra`)

| | zlib | fx3d | misc |
|---|---|---|---|
| -O2 | +1.4% cycles | −0.7% | −0.3% |
| -Os | +0.05% | +0.04% | −1.7% cycles, −3.5% `.text` |

Torture results are unchanged. Not a clear win; not adopted.

### 13. Fixed-point divide with the SH7604 divider (DIVU)

Not implemented; analysis only.

- `-mdiv` on SH-2 is stuck with `call-div1`: libgcc's `__udivsi3` is a
  `div1` loop of about 40–70 cycles, close to DIVU's 39 cycles plus its
  register loads and stores, so plain 32/32 division would gain little.
- The large gain is 64/32 (fixed-point `((long long)a << 16) / b`), which
  goes through libgcc's `__divdi3`; DIVU does it in 39 cycles.
- A compiler option would have to be opt-in: interrupt handlers that use
  DIVU would corrupt it, and its overflow behaviour differs from C.
- SaturnMath++ already drives DIVU directly, including overlapping a
  divide with other CPU work, which a libgcc routine cannot do.

### 14. Section anchors for globals

Not implemented. The SH backend does not define anchor offsets, so
`-fsection-anchors` does nothing. Each global access costs a PC-relative
load plus a 4-byte literal-pool entry; anchors would share one base, but
SH displacements are tiny (15 bytes for bytes, 30 for words, 60 for
longs), so the expected gain is small.

### 15. `-mdiv=call-table`

Requires dynamic shift instructions (`shad`/`shld`, SH-3 and later); the
SH-2 is limited to `-mdiv=call-div1`.

## Branch status

| Branch | GCC patches | soft-fp | Section-built libs | `-mrelax` fix |
|---|---|---|---|---|
| 8.4, 9.5, 10.4, 11.5, 12.4, 13.3 | 0001, 0002, 0003 | – | – | yes |
| 11.3.0, 12.2.0, 12.3.0, 13.2.0, 14.1.0 `_deprecated` | – | – | – | yes |
| 14.2 | 0001, 0002, 0003 | – | – | yes |
| 14.3 | 0001, 0002, 0003 (extended), 0004 | yes | yes | yes |
| 15.1, 15.2, master | – | – | – | yes |
| 15.3, 16.1, 16.2 | 0001, 0003 | – | – | yes |

Not yet ported: soft-fp, section-built libraries and the extended
pre-decrement patch (14.3 only); GCC patches 0001/0003 to 15.1, 15.2 and
master.
