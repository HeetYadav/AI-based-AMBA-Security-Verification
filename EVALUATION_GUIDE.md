# Evaluation & Command Guide

This document provides the exact sequence of commands required to evaluate the project and the expected output for each stage.

---

## 1. Environment Setup
Before running anything, ensure your Python environment is initialized.

**Command:**
```bash
python setup_env.py
```
**Expected Output:**
- `[INFO] Installing dependencies...`
- `[INFO] Environment check passed. All libraries (pandas, numpy, scikit-learn, matplotlib) are available.`

---

## 2. Hardware Simulation (ModelSim / Questa)
This stage compiles the RTL, runs the verification suite, and generates the bus traces.

**Commands:**
1. Open ModelSim/Questa.
2. Change directory to the `sim/` folder.
3. Run the multi-variant simulation:
```tcl
do run_sim.do
```

**Expected Output in ModelSim Transcript:**
- **Compilation:** Messages showing `apb_master`, `apb_slave`, and `stealth_trojan` compiling without errors.
- **Variant A Pass:** You should see `[TROJAN DETECTED] Variant=A Cycle=103 ...`
- **Variant B Pass:** You should see `[TROJAN DETECTED] Variant=B Cycle=...`
- **Variant C Pass:** You should see `[TROJAN DETECTED] Variant=C Cycle=...`
- **Final Message:** `All three variant simulations complete.`

---

## 3. AI Detection Pipeline (Python)
This stage analyzes the traces generated in Step 2 to detect the Trojans using Machine Learning.

**Command:**
```bash
python scripts/run_pipeline.py
```

**Expected Output in Terminal:**
- **ASCII Comparison Table:**
  ```text
  ┌─────────────────────┬──────────────┬───────────────┐
  │ Model               │ Full Mode F1 │ Blind Mode F1 │
  ├─────────────────────┼──────────────┼───────────────┤
  │ Isolation Forest    │    1.000     │    0.852      │
  │ One-Class SVM       │    1.000     │    0.790      │
  └─────────────────────┴──────────────┴───────────────┘
  ```
- **Detection Logs:** `[INFO] Variant A: Trojan first flagged at Cycle 103.`
- **Visuals:** The script will save `.png` plots in the `results/` folder.

---

## 4. Summary of Verification Files
- **Bus Traces:** Located in `dataset/trace_log_A.csv`, etc.
- **Waveforms:** Open `dataset/trace_A.vcd` in ModelSim to see signal-level Trojan activation.
- **Detection Metrics:** Located in `results/detection_results_A_full.json`, etc.
