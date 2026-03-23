# Scripts

This directory contains the utility and orchestration scripts for the project. After the file reorganization, it serves as the central location for all Python tooling: environment setup, pipeline execution, report computation, and VCD extraction.

## Scripts Reference

### `run_pipeline.py` — Master Pipeline

The primary entry point for the AI analysis phase. It sequentially:

1. Verifies that simulation traces exist in `dataset/`.
2. Runs `anomaly_detection.py` for all three Trojan variants (A, B, C).
3. Runs `lstm_detector.py` for the sequential windowed analysis.
4. Prints a consolidated ASCII comparison table to the terminal.

```bash
python scripts/run_pipeline.py
```

### `setup_env.py` — Environment Initialization

Checks whether all required Python packages are installed and installs any that are missing. Run this once before any other script.

```bash
python scripts/setup_env.py
```

Required packages: `pandas`, `numpy`, `matplotlib`, `scikit-learn`, `tabulate`

### `compute_report_values.py` — Report Metrics

Computes all empirical values required for the project report:

- Confusion matrices (TP, TN, FP, FN) for all six variant/mode combinations
- Detection rates for bar chart visualization
- Feature mean separation (normal vs. anomaly) for each variant
- Address coverage statistics across eight 32-address bins

```bash
python scripts/compute_report_values.py
```

Output is printed to the terminal. A reference snapshot of the output is saved at `results/results_report.txt`.

### `tempCodeRunnerFile.py`

Auto-generated scratch file created by VS Code's Code Runner extension. It has no project function and is safe to ignore or delete.

## Notes

The `ai/extract_vcd.py` script provides a fallback path to extract transaction data from standard IEEE 1364 VCD waveforms if direct CSV logging from the testbench is unavailable. It is invoked manually, not as part of the standard pipeline.
