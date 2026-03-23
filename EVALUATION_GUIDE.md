# Evaluation and Command Guide

This document provides the exact sequence of commands required to evaluate the project, along with expected output for each stage.

## 1. Environment Setup

Before running anything, initialize the Python environment to ensure all dependencies are present.

```bash
python scripts/setup_env.py
```

Expected output:

```
============================================================
 Project Environment Initialization
============================================================
[INFO] All dependencies are already installed.
[INFO] Checking availability...
[SUCCESS] Environment check passed. Ready to run the pipeline.
```

## 2. Hardware Simulation (ModelSim / Questa)

This stage compiles the RTL, runs the verification suite, and generates the bus traces written to `dataset/`.

1. Open ModelSim or Questa.
2. Change directory to `sim/`.
3. Run the multi-variant simulation script:

```tcl
do run_sim.do
```

Expected transcript output:

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

## 3. AI Detection Pipeline

This stage reads the simulation traces and runs the anomaly detection models.

```bash
python scripts/run_pipeline.py
```

Expected terminal output:

```
+---------------------+--------------+---------------+
| Model               | Full Mode F1 | Blind Mode F1 |
+---------------------+--------------+---------------+
| Isolation Forest    |    0.800     |    0.800      |
| One-Class SVM       |    0.364     |    0.400      |
+---------------------+--------------+---------------+
```

PNG timeline plots are saved to the `results/` directory.

## 4. Report Metrics Computation

To recompute all empirical values used in the project report (confusion matrices, detection rates, feature separation statistics, address coverage):

```bash
python scripts/compute_report_values.py
```

This script reads from `dataset/` and prints a full breakdown per Trojan variant and detection mode. A reference copy of the output is saved at `results/results_report.txt`.

## 5. Output File Locations

| Artifact | Location | Description |
|---|---|---|
| Bus traces | `dataset/trace_log_A.csv` | One CSV per Trojan variant |
| VCD waveforms | `dataset/trace_A.vcd` | Open in ModelSim Wave viewer |
| Detection JSON | `results/detection_results_A_full.json` | Per-variant, per-mode metrics |
| Detection plots | `results/*.png` | Timeline and transaction visualizations |
| Report metrics | `results/results_report.txt` | Full confusion matrix summary |
