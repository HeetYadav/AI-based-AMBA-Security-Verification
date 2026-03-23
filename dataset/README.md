# Simulation Datasets

This directory stores all behavioral data generated during hardware simulation. It is the data boundary between the hardware verification layer (ModelSim) and the AI detection layer (Python).

## File Formats

### CSV Transaction Logs (`trace_log_*.csv`)

Generated directly by the SystemVerilog testbench via `$fwrite`. Each file is the primary input for the AI pipeline.

| Column | Type | Description |
|---|---|---|
| `cycle` | int | Simulation clock cycle at transaction completion |
| `paddr` | hex | APB address bus value |
| `pwdata` | hex | APB write data bus value |
| `prdata` | hex | Read data returned by the infected slave |
| `prdata_golden` | hex | Read data returned by the golden reference slave |
| `pwrite` | bit | Transaction direction: 1 = Write, 0 = Read |
| `psel` | bit | Slave select signal |
| `penable` | bit | Enable signal (marks ACCESS phase) |
| `data_error` | hex | XOR of `prdata` and `prdata_golden`; non-zero indicates payload corruption |
| `trojan_active` | bit | Asserted by the Trojan module when it fires; ground-truth label for evaluation |

One file exists per Trojan variant: `trace_log_A.csv`, `trace_log_B.csv`, `trace_log_C.csv`.

### VCD Waveforms (`trace_*.vcd`)

Standard IEEE 1364 Value Change Dump files produced by ModelSim. Open these in ModelSim or Questa to view signal-level timing diagrams and confirm the exact clock cycle of Trojan activation.

### Sample Trace (`sample_trace_log.csv`)

A pre-generated minimal trace provided for initial AI pipeline verification. It allows running and testing the Python scripts without first completing a full hardware simulation pass.
