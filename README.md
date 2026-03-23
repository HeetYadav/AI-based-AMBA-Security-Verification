# AI-Assisted Hardware Trojan Detection in AMBA APB Systems

![License](https://img.shields.io/badge/license-Academic-blue)
![Language](https://img.shields.io/badge/RTL-Verilog%20%2F%20SystemVerilog-orange)
![AI](https://img.shields.io/badge/ML-scikit--learn-green)
![Course](https://img.shields.io/badge/Course-TVDC%20%E2%80%93%20B.Tech%20Sem%20VI-lightgrey)

A complete **pre-silicon security verification framework** that combines AMBA APB bus simulation, three stealth Hardware Trojan variants, and an unsupervised AI anomaly detection pipeline. The project demonstrates that traditional SVA-based protocol verification is insufficient against semantically stealthy Trojans, and that machine learning provides a mandatory complementary detection layer.

---

## Project Overview

| Layer | Technology | Purpose |
|---|---|---|
| RTL Design | Verilog IEEE-1364 | AMBA APB Master, infected Slaves, Trojans, Golden Reference |
| Verification | SystemVerilog (SVA, covergroups) | Protocol assertions + functional coverage |
| Simulation | ModelSim / Questa | Compile, run, log bus traces to CSV |
| AI Detection | Python + scikit-learn | Isolation Forest, One-Class SVM, Windowed IF |

---

## Quick Start

### 1. Initialize Python Environment
```bash
python setup_env.py
```
Expected: `[SUCCESS] Environment check passed. Ready to run the pipeline.`

### 2. Hardware Simulation (ModelSim / Questa)
```
cd sim/
do run_sim.do
```
Expected transcript messages:
- `[TROJAN DETECTED] Variant=A Cycle=103`
- `[TROJAN DETECTED] Variant=B Cycle=...`
- `[TROJAN DETECTED] Variant=C Cycle=...`

### 3. AI Detection Pipeline
```bash
python scripts/run_pipeline.py
```
Results are printed as ASCII tables and saved to `results/detection_results_*.json`.

---

## Repository Structure

```
project/
├── rtl/            Verilog RTL: Master, Slaves, Trojans, Golden Reference
├── tb/             SystemVerilog: Top testbench, SVA assertions, coverage
├── sim/            ModelSim automation scripts
├── ai/             Python anomaly detection models
├── dataset/        Simulation trace logs (CSV format)
├── results/        JSON detection metrics and PNG plots
├── scripts/        Pipeline orchestration
└── docs/           In-depth guides and design documents
```

---

## Detection Results (Verified Pipeline Output)

| Trojan | Type | IF Full F1 | IF Blind F1 | SVM Full F1 | SVM Blind F1 |
|---|---|:---:|:---:|:---:|:---:|
| Variant A | 5-cond AND trigger, XOR-0xDE | 0.000 | 0.000 | 0.000 | 0.000 |
| Variant B | Counter+addr guard, 1-bit flip | 0.500 | 0.800 | 0.364 | 0.400 |
| Variant C | Sequential 3-read trigger, 0xFF | 0.500 | 0.800 | 0.364 | 0.400 |

> **Variant A** trigger probability ≈ 1/134,217,728; the trigger did not fire within the 995-transaction trace, making detection impossible without extended simulation.

---

## Documentation

| Document | Description |
|---|---|
| [EVALUATION_GUIDE.md](EVALUATION_GUIDE.md) | Step-by-step command reference with expected outputs |
| [docs/FULL_PROJECT_GUIDE.md](docs/FULL_PROJECT_GUIDE.md) | Detailed beginner-friendly project guide |
| [docs/TROJAN_DESIGN.md](docs/TROJAN_DESIGN.md) | Technical specification of the three Trojan variants |
| [docs/AI_PIPELINE.md](docs/AI_PIPELINE.md) | Deep dive into the ML models and feature engineering |
| [docs/VERIFICATION.md](docs/VERIFICATION.md) | SVA properties and functional coverage methodology |

---

## Technology Stack

- **RTL:** Verilog (IEEE 1364-2001), synthesizable, ModelSim/Questa compatible
- **Testbench:** SystemVerilog IEEE 1800-2017 (SVA, covergroups, `$fwrite` CSV logging)
- **Python:** 3.9+, pandas, numpy, scikit-learn, matplotlib, tabulate
