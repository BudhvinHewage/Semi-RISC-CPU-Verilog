# CPU Testing Guide

Covers how to run and verify the 37-instruction coverage program in both
simulation and on real hardware. Same program, two environments — this
doc treats them together since they share the same expected-value table.

## The Test Program

```
0000000A  10000004  70000000  72000000  71000006  73000000  7E000000
000000F0  1000000F  7B000000  000000F0  7D00000F  00000003  74000000
7F000000  000000FF  7900000F  75000000  10000063  76000000  00000007
10000007  80000000  7A000000  00000378  78000000  7A000000  0000006F
77000000  7C000000  000000DE  10000037  30000032  1000004D  A0000032
40001234  50000024
```

| Addr | Instr | What to expect |
|------|-------|-----------------|
| 0  | LDAI 10  | A = 0x0000000A |
| 1  | LDBI 4   | B = 0x00000004 |
| 2  | ADD      | A = 0x0000000E (14) |
| 3  | SUB      | A = 0x0000000A (10 — round-trip vs addr 0) |
| 4  | ADDI 6   | A = 0x00000010 (16) |
| 5  | INCA     | A = 0x00000011 (17) |
| 6  | DECA     | A = 0x00000010 (16 — round-trip vs addr 4) |
| 7  | LDAI 0xF0| A = 0x000000F0 |
| 8  | LDBI 0x0F| B = 0x0000000F |
| 9  | AND      | A = 0x00000000 |
| 10 | LDAI 0xF0| A = 0x000000F0 |
| 11 | ORI 0x0F | A = 0x000000FF |
| 12 | LDAI 3   | A = 0x00000003 |
| 13 | ROL      | A = 0x00000006 |
| 14 | ROR      | A = 0x00000003 (round-trip vs addr 12) |
| 15 | LDAI 0xFF| A = 0x000000FF |
| 16 | ANDI 0x0F| A = 0x0000000F |
| 17 | CLRA     | A = 0x00000000 |
| 18 | LDBI 99  | B = 0x00000063 |
| 19 | CLRB     | B = 0x00000000 |
| 20 | LDAI 7   | A = 0x00000007 |
| 21 | LDBI 7   | B = 0x00000007 |
| 22 | BNE 0    | not taken; Z becomes 1 as a side effect |
| 23 | TSTZ     | Z=1 -> skips addr 24 |
| 24 | LDAI 888 | **must never execute** — poison |
| 25 | CLRZ     | Z becomes 0 |
| 26 | TSTZ     | Z=0 -> does NOT skip |
| 27 | LDAI 111 | A = 0x0000006F — proves addr 26 didn't skip |
| 28 | CLRC     | C becomes 0 |
| 29 | TSTC     | C=0 -> does NOT skip |
| 30 | LDAI 222 | A = 0x000000DE — proves addr 29 didn't skip |
| 31 | LDBI 55  | B = 0x00000037 |
| 32 | STB 50   | M[50] = 55 |
| 33 | LDBI 77  | B = 0x0000004D (clobber) |
| 34 | LDB 50   | B = 0x00000037 (55 again — round-trip through memory) |
| 35 | LUI 0x1234| A = 0x12340000 |
| 36 | JMP 36   | halt — self-loop, program stays here forever |

## Simulation (Vivado XSim)

**Setup:** `tb_cpu_top.v` drives `cpu_top_test`, which wires `cpu1` +
`instr_mem` together. Set `tb_cpu_top` as simulation top, then
**Flow Navigator → Simulation → Run Behavioral Simulation**.

**Add to the waveform:** `out_a`, `out_b`, `out_c`, `out_z`, `out_ir`,
`out_pc`, `t_info`.

**Reading rule, worth restating:** a register's new value is only valid
starting at the clock edge where `t_info` flips `4 → 1` (T2 ending, back to
T0). Checking a value mid-T2 will show the *old* contents — that's not a
bug, it's how a clocked register works.

**What to actually check:** walk the table above against the waveform, in
order. The two most diagnostic moments are addr 24 (confirm `A` never
shows `888`) and addr 34 (confirm `B` returns to `55`, not `77`) — those
two alone prove the flag-persistence and memory-persistence mechanisms
are real, not just "the CPU ran without crashing."

**Known limitation, not a bug to chase:** addr 28–30 only prove `TSTC`
correctly *doesn't* skip when `C=0`. Nothing in the current design sets
`C=1`, so there's no way to test the skip-when-set case yet — a real,
existing gap in the design, not a simulation problem.

## Hardware (Basys 3)

**Setup:** generate the bitstream against `cpu_basys3_top.v` +
`basys3.xdc`, program the board via Hardware Manager.

**Controls:**

| Control | Function |
|---------|----------|
| BTNU | Reset — hold, then release |
| BTNC | Clock step — **one press = one T-state**, not one instruction |
| SW0 | Display A |
| SW1 | Display B |
| SW2 | Display PC |
| SW3 | Display IR |
| SW4 | Display status C |
| SW5 | Display status Z |
| SW6 | Display ALU |
| LD0 / LD1 / LD2 | Always on — lit for T0 / T1 / T2, regardless of SW |

Only one of SW0–SW5 should be on at a time — SW0 wins if more than one is
set. Switches can be flipped at any time without affecting the clock —
safe to change what you're viewing between button presses. LD0–LD2 are
always live, so you can tell what T-state you're in no matter what else
is selected.

**Fast confidence check (12 presses, proves the board works before
committing to a full walk):**

1. Press and release BTNU.
2. Press BTNC **3 times** (completes addr 0, `LDAI 10`). Set `SW0=1`
   (all others off) — hex display should read `000A`.
3. Press BTNC **3 more times** (addr 1, `LDBI 4`). Switch to `SW1=1` —
   should read `0004`.
4. Press BTNC **3 more times** (addr 2, `ADD`). Back to `SW0=1` — should
   now read `000E` (14).
5. Press BTNC **3 more times** (addr 3, `SUB`). `SW0=1` should read
   `000A` (10) again — the same round-trip you already proved in
   simulation, now visibly reproduced on real silicon.

Throughout, LD0/LD1/LD2 should visibly step 1-0-0 → 0-1-0 → 0-0-1 and
back with every single press — a quick sanity check that the clock-step
circuit is registering each press as exactly one T-state.

**Full walk:** continue the same pattern — 3 presses per instruction,
against the table above — for all 37 instructions (111 presses total).
Only worth doing in full if you specifically want hardware confirmation
beyond the fast check, since simulation has already proven the logic.

**If something looks wrong that simulation already proved correct:**
suspect contact bounce on BTNC first, not the CPU's logic. The current
clock-step circuit is a plain edge detector with no debounce yet — a
single physical press can register as several rapid presses, which would
show up as a value that's a few extra T-states ahead of where you expect,
not as a wrong computed value. A genuinely wrong *value* (not just being
at an unexpected T-state) is the more meaningful signal of a real bug,
since that's not something bounce would explain.