# RTL Design — `rtl/`

This directory contains the synthesisable Verilog (IEEE 1364-2001) source files for the AMBA APB hardware system. All modules are designed for simulation in ModelSim/Questa and follow standard APB protocol timing.

---

## Module Reference

### `apb_master.v` — APB Bus Master
The master drives all bus traffic used to exercise the Trojan trigger conditions.

| Signal | Direction | Width | Description |
|---|---|:---:|---|
| `PCLK` | Input | 1 | System clock — all outputs register on rising edge |
| `PRESETn` | Input | 1 | Active-low synchronous reset |
| `PADDR` | Output | 8 | Address bus driven in SETUP phase |
| `PWDATA` | Output | 8 | Write data driven in SETUP phase |
| `PWRITE` | Output | 1 | Direction: 1 = Write, 0 = Read |
| `PSEL` | Output | 1 | Slave select — asserted in SETUP and ACCESS |
| `PENABLE` | Output | 1 | Enable — asserted only in ACCESS phase |
| `PRDATA` | Input | 8 | Read data returned by slave |
| `PREADY` | Input | 1 | Handshake — extends transaction when low |

**Traffic Phases:**

| Phase | Name | Transactions | Description |
|---|---|:---:|---|
| 0 | `PHASE_NORM_WR` | 30 | Sequential writes, addr 0x00–0x1D |
| 1 | `PHASE_NORM_RD` | 30 | Sequential reads, addr 0x00–0x1D |
| 2 | `PHASE_RANDOM` | 40 | LFSR-driven pseudo-random R/W transactions |
| 3 | `PHASE_TROJAN` | 10 | Directed sequence to fire Variant A trigger |
| 4 | `PHASE_SEQ_RD` | 10 | Sequential reads 0x01→0x02→0x03 for Variant C |

**PRNG:** 16-bit Galois LFSR (seed: `0xACE1`, polynomial: x¹⁶+x¹⁴+x¹³+x¹¹+1) drives address and data in Phase 2.

---

### `apb_slave_golden.v` — Golden Reference Slave
A Trojan-free 256×8-bit memory-mapped peripheral. Runs in parallel with the infected DUT during simulation. Its `PRDATA` output is XORed with the infected slave to compute `data_error`.

- Always-ready (`PREADY = 1`, zero wait states)
- Synchronous write on `PSEL && PENABLE && PWRITE`
- Combinational read gated by `PSEL && !PWRITE`

---

### `apb_slave.v` / `apb_slave_b.v` / `apb_slave_c.v` — Infected Slaves
Wrapper modules that instantiate the standard register file alongside the respective Trojan sub-module. Port-compatible with the golden slave — can be swapped transparently.

---

### `stealth_trojan.v` — Variant A Trojan
**Trigger:** 5-condition AND: `PADDR==0xAA && PWDATA==0x55 && PWRITE==1 && prev_addr==0x10 && cycle_count>200`  
**Payload:** XOR read data with `SECRET_KEY = 0xDE`  
**Trigger probability:** ≈ 1/134,217,728  
**Key ports:** `normal_prdata[7:0]` (in), `trojan_prdata[7:0]` (out), `trojan_active` (out)

---

### `stealth_trojan_b.v` — Variant B Trojan
**Trigger:** Write to `PADDR==0x7F` after `trans_count > 50` completed transactions  
**Payload:** XOR read data with `SECRET_KEY_B = 0x01` (single-bit flip)  
**Stealth:** Activation delayed until after standard short-run tests complete

---

### `stealth_trojan_c.v` — Variant C Trojan
**Trigger:** Three consecutive reads to addresses `0x01 → 0x02 → 0x03` (3-deep shift-register history, reads only)  
**Payload:** Force `PRDATA = 0xFF` on the subsequent read  
**Stealth:** Sequential condition survives any random testing without deliberate directed stimulus

---

## Compilation Order (ModelSim)

Compile leaves before roots:
```tcl
vlog -sv rtl/apb_slave_golden.v
vlog -sv rtl/stealth_trojan.v rtl/stealth_trojan_b.v rtl/stealth_trojan_c.v
vlog -sv rtl/apb_slave.v rtl/apb_slave_b.v rtl/apb_slave_c.v
vlog -sv rtl/apb_master.v
```
