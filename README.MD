# Semi-RISC CPU (Verilog)

A from-scratch Verilog redesign of a 26-instruction, multi-cycle CPU architecture,
rebuilt from an earlier VHDL coursework implementation to properly re-derive the
control and datapath logic rather than transliterate it. Targets the Digilent
Basys 3 (Artix-7); simulated in Vivado and running on real hardware.

## Architecture

Harvard architecture (separate instruction/data memory), semi-RISC, load/store
type, two 32-bit working registers (A, B) plus 1-bit Carry (C) and Zero (Z)
status flags. Every instruction executes in exactly three clock cycles — T0
(fetch), T1 (advance PC / early-assert memory or comparison signals), T2
(execute) — driven by a Moore FSM in the control unit.

```
cpu (top)
├── reset_circuit — holds the FSM idle for 4 cycles after reset deasserts
├── control        — T0/T1/T2 FSM, decodes IR into ~20 datapath control signals
└── data_path
    ├── register32 (x2)  — A, B
    ├── register1 (x2)   — C, Z status flags
    ├── pc               — program counter (increment-or-load)
    ├── ALU              — 8-operation ALU (AND/OR/ADD/SUB/shifts/pass-through)
    ├── data_mem         — 256 x 32-bit data memory
    ├── LZE / UZE / RED  — immediate/address extraction from IR
    └── mux2to1 / mux4to1 — datapath routing (shared-bus architecture)

instr_mem — 64 x 32-bit instruction memory (behavioral, $readmemh-loaded)
```

Like the underlying VHDL, this uses a shared-bus datapath: one 32-bit bus,
one writer per cycle (external fetch / memory read / ALU result), selected by
`data_mux`. That constraint is the reason the design is multi-cycle rather
than single-cycle.

## Instruction Set

10 "addressing" instructions, selected by `IR[31:28]`:

| Code | Instr | Operation |
|------|-------|-----------|
| 0000 | LDAI  | A <= IR[15:0] |
| 0001 | LDBI  | B <= IR[15:0] |
| 0010 | STA   | M[IR[7:0]] <= A |
| 0011 | STB   | M[IR[7:0]] <= B |
| 0100 | LUI   | A[31:16] <= IR[15:0], A[15:0] <= 0 |
| 0101 | JMP   | PC <= IR[15:0] |
| 0110 | BEQ   | if A==B, PC <= IR[15:0] |
| 1000 | BNE   | if A!=B, PC <= IR[15:0] |
| 1001 | LDA   | A <= M[IR[7:0]] |
| 1010 | LDB   | B <= M[IR[7:0]] |

16 "data-processing" instructions, selected by `IR[27:24]` when
`IR[31:28] == 0111`:

| Code | Instr | Operation |
|------|-------|-----------|
| 0000 | ADD   | A <= A+B |
| 0001 | ADDI  | A <= A+IR[15:0] |
| 0010 | SUB   | A <= A-B |
| 0011 | INCA  | A <= A+1 |
| 0100 | ROL   | A <= A<<1 |
| 0101 | CLRA  | A <= 0 |
| 0110 | CLRB  | B <= 0 |
| 0111 | CLRC  | C <= 0 |
| 1000 | CLRZ  | Z <= 0 |
| 1001 | ANDI  | A <= A AND IR[15:0] |
| 1010 | TSTZ  | if Z=1, PC <= PC+1 (skip next instruction) |
| 1011 | AND   | A <= A AND B |
| 1100 | TSTC  | if C=1, PC <= PC+1 |
| 1101 | ORI   | A <= A OR IR[15:0] |
| 1110 | DECA  | A <= A-1 |
| 1111 | ROR   | A <= A>>1 |

Note: `STA`/`STB`/`LDA`/`LDB` address memory via the lower **8** bits of `IR`
(`RED`). `JMP`/`BEQ`/`BNE` and the immediate-load instructions use the lower
**16** bits (`LZE`) — same instruction word, two different field widths
depending on instruction type.

## Design decisions made during the rebuild

The reference VHDL this was rebuilt from had real, unresolved gaps — not
matters of style, matters of missing functionality:

- **Status flag registers (`Reg_C`/`Reg_Z`) were never instantiated** in the
  original, despite `CLRZ`/`CLRC`/`TSTZ`/`TSTC` depending on them existing.
  Added `register1` instances driven by the ALU's `zero`/`cout` outputs.
- **`BEQ`/`BNE` compare A and B live**, not via a persisted flag — matching
  the spec's own pseudocode (`IF(A==B)`) and how the ISA's own bonus
  exercises expect branches to compose without a dedicated compare
  instruction. They reuse the same T1 early-assert pattern built for memory
  timing: route A/B into the ALU with `alu_op=SUB` and `ld_z=1` one cycle
  ahead of when T2 needs to read the result.
- **A dangling-signal bug in the original top level** (`wen_mem`/`en_mem`
  wired to undriven signals instead of the live memory-enable wires) was
  found and fixed during translation.
- **`wen`/`en` are asserted across both T1 and T2** for memory instructions,
  rather than relying on an exact phase relationship between `clk` and
  `mclk` that nothing in the design actually guarantees.

## Simulation

`instr_mem` is loaded via `$readmemh("program.hex", mem)` — no vendor RAM
IP, unlike the original Quartus MegaCore dependency. `cpu_top_test.v` wires
`cpu` + `instr_mem` together for simulation (instruction address truncated
to the memory's 6-bit width; nothing in this ISA writes program memory at
runtime, so `wren` is tied low). `tb_cpu_top.v` drives reset and lets the
program run.

Verified in simulation, with programs specifically designed to prove
correctness rather than just "something happened": memory read/write
persistence (write, deliberately overwrite, read back), conditional
branching with a "poison value" that must never execute if a branch is
taken correctly, and round-trip checks across every arithmetic/logic
instruction (e.g. `ADD` then `SUB` returning to the original value). See
`TESTING.md` for the full program and expected-value table.

## Hardware bring-up

`cpu_basys3_top.v` + `sseg_display.v` + `basys3.xdc` target real hardware.
`mem_clk` runs off the board's native 100MHz oscillator; `clk` is driven by
a manually-stepped pushbutton (`BTNC`) — one press advances the FSM by
exactly one T-state, giving full manual control for observing each phase.
`SW0`–`SW5` (soon `SW0`–`SW6`, once the port-width fix above lands) select
which internal signal is shown across the 4-digit 7-segment display and 16
LEDs; `LD0`–`LD2` permanently mirror the current T-state regardless of what
else is selected. Full control scheme
and step-by-step verification walkthrough in `TESTING.md`.

**Real bug hit and fixed during bring-up, worth keeping as a debugging
story:** `program.hex` initially only lived in Vivado's Simulation Sources
fileset. XSim could see it fine, so simulation worked correctly — but
synthesis builds block-RAM contents from the Design Sources fileset only,
and doesn't error when it can't find an init file, it just zero-initializes
silently. Every fetched instruction decoded as `LDAI #0`, which looked like
"nothing is working" rather than obviously pointing at a memory-loading
problem — `PC` still advanced normally (T1's increment fires regardless of
instruction content), which is what made the symptom initially confusing.
Fixed by adding `program.hex` under Design Sources instead.

Synthesis, implementation, and bitstream generation complete. Initial
on-board execution confirmed correct for the first several instructions;
full-program hardware verification still in progress.

## Status

- [x] All modules rebuilt in Verilog from re-derived control/datapath logic
- [x] Control unit's 26-instruction decode independently derived and verified
- [x] Core datapath mechanisms proven via simulation (memory, branching)
- [x] Synthesis / implementation / bitstream generation on Basys 3
- [x] Initial on-board execution confirmed (first several instructions)
- [x] Full-program hardware verification
- [ ] Debounced clock-step input (currently raw edge-detect only)
- [ ] Bonus: hand-assembled multi-branch and loop test programs

## Future work

- Multiply/divide: not part of the current ISA. Would require reclaiming
  opcode space (currently fully allocated across 26 instructions) rather
  than a simple addition — a real ISA-scope decision, not started here.
- Debounce circuit for the hardware clock-step button — deliberately
  deferred as a separate, standalone exercise.

## Background

Rebuilt from an earlier VHDL implementation of the same architecture,
originally completed as coursework. This redesign specifically targets
independently re-deriving the control unit's instruction decode logic and
resolving design gaps in the original, rather than transliterating a known
solution.