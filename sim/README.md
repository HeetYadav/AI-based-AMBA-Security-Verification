# Simulation Environment — `sim/`

This directory contains the ModelSim/Questa automation scripts for compiling the RTL and testbench, running all three Trojan variant simulations, and generating the behavioral trace logs.

---

## `run_sim.do` — Main Simulation Script

A ModelSim TCL `.do` script that performs the full simulation flow in a single command.

**What it does:**
1. Creates a fresh `work` library (`vlib work`, `vmap work work`).
2. Compiles all RTL Verilog sources with `-sv` flag for SystemVerilog compatibility.
3. Runs three simulation passes — one per Trojan variant (A, B, C) — using the `TROJAN_VARIANT` elaboration parameter.
4. Writes CSV trace logs to `dataset/trace_log_{A,B,C}.csv` and VCD waveform files to `dataset/trace_{A,B,C}.vcd`.

**Usage:**
```tcl
# From inside ModelSim / Questa transcript:
do run_sim.do
```

**Expected transcript output:**
```
# [INFO] Compiling RTL...
# [INFO] Running Variant A...
# [TROJAN DETECTED] Variant=A Cycle=103 PADDR=aa PRDATA_INFECTED=... PRDATA_GOLDEN=...
# [INFO] Running Variant B...
# [TROJAN DETECTED] Variant=B Cycle=...
# [INFO] Running Variant C...
# [TROJAN DETECTED] Variant=C Cycle=...
# All three variant simulations complete.
```

---

## Compilation Command Reference

For manual compilation, use the following sequence:
```tcl
vlib work
vmap work work
vlog -sv ../rtl/apb_slave_golden.v
vlog -sv ../rtl/stealth_trojan.v ../rtl/stealth_trojan_b.v ../rtl/stealth_trojan_c.v
vlog -sv ../rtl/apb_slave.v ../rtl/apb_slave_b.v ../rtl/apb_slave_c.v
vlog -sv ../rtl/apb_master.v
vlog -sv ../tb/coverage.sv ../tb/assertions.sv ../tb/apb_tb.sv
```

**Elaboration with variant selection:**
```tcl
vsim -G TROJAN_VARIANT=\"A\" apb_tb
run -all
```

---

## Generated Outputs

| File | Location | Description |
|---|---|---|
| `trace_log_A.csv` | `dataset/` | 995-transaction bus trace for Variant A |
| `trace_log_B.csv` | `dataset/` | 20-transaction trace for Variant B |
| `trace_log_C.csv` | `dataset/` | 20-transaction trace for Variant C |
| `trace_A.vcd` | `dataset/` | VCD waveform — open in ModelSim Wave viewer |

---

## Notes

- The `work/` directory is the ModelSim compiled library and is auto-generated; do not commit it to version control (covered by `.gitignore`).
- `modelsim.ini` configures library paths and is required for correct elaboration.
- To view waveforms: In ModelSim, use `File > Open > dataset/trace_A.vcd` and add signals from the hierarchy panel.
