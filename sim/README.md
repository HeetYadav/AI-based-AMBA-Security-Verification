# Simulation Environment

This directory contains the ModelSim/Questa automation scripts that compile the RTL and testbench, run all three Trojan variant simulations, and generate the behavioral trace logs written to `dataset/`.

## `run_sim.do` — Main Simulation Script

A ModelSim TCL `.do` script that performs the complete simulation flow in a single command.

**What it does:**

1. Creates a fresh `work` library (`vlib work`, `vmap work work`).
2. Compiles all Verilog and SystemVerilog source files from `rtl/` and `tb/`.
3. Runs three simulation passes, one per Trojan variant (A, B, C), using the `TROJAN_VARIANT` elaboration parameter.
4. Writes CSV trace logs to `dataset/trace_log_{A,B,C}.csv` and VCD waveform files to `dataset/trace_{A,B,C}.vcd`.

**Usage — from inside ModelSim/Questa:**

```tcl
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

## Manual Compilation Reference

For step-by-step manual compilation, use the following sequence from the `sim/` directory:

```tcl
vlib work
vmap work work
vlog -sv ../rtl/apb_slave_golden.v
vlog -sv ../rtl/stealth_trojan.v ../rtl/stealth_trojan_b.v ../rtl/stealth_trojan_c.v
vlog -sv ../rtl/apb_slave.v ../rtl/apb_slave_b.v ../rtl/apb_slave_c.v
vlog -sv ../rtl/apb_master.v
vlog -sv ../tb/coverage.sv ../tb/assertions.sv ../tb/apb_tb.sv
```

Elaboration with variant selection:

```tcl
vsim -G TROJAN_VARIANT=\"A\" apb_tb
run -all
```

## Generated Output Files

| File | Location | Description |
|---|---|---|
| `trace_log_A.csv` | `dataset/` | 995-transaction bus trace for Variant A |
| `trace_log_B.csv` | `dataset/` | 20-transaction trace for Variant B |
| `trace_log_C.csv` | `dataset/` | 20-transaction trace for Variant C |
| `trace_A.vcd` | `dataset/` | VCD waveform for Variant A |

## Notes

- The `work/` subdirectory is the ModelSim compiled library. It is auto-generated and excluded from version control by `.gitignore`.
- `modelsim.ini` configures library paths and must remain present for correct elaboration.
- To view waveforms after simulation: in ModelSim, open `dataset/trace_A.vcd` via `File > Open` and add signals from the hierarchy panel.
