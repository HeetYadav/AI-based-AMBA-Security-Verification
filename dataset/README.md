# Simulation Datasets

This directory serves as the data warehouse for the project. It stores the raw behavioral traces generated during hardware simulation.

## 📄 File Formats

### 1. CSV Transaction Logs (`trace_log_*.csv`)
Generated directly by the SystemVerilog testbench. This is the primary input for the AI pipeline.
*   **Columns:** `cycle`, `paddr`, `pwdata`, `prdata`, `prdata_golden`, `pwrite`, `psel`, `penable`, `data_error`, `trojan_active`.
*   **Significance:** Each row represents a completed AMBA APB transaction.

### 2. VCD Waveforms (`trace_*.vcd`)
Standard IEEE 1364 Value Change Dump files.
*   **Usage:** Open these in ModelSim/Questa to view signal-level timing diagrams and verify the exact point of Trojan activation.

## 🧪 Sample Data
*   `sample_trace_log.csv`: A pre-generated mini-trace provided for initial AI pipeline verification without requiring a full hardware simulation pass.
