# AI-Assisted Hardware Trojan Detection in AMBA APB Systems

![License](https://img.shields.io/badge/license-Academic-blue)
![RTL](https://img.shields.io/badge/RTL-Verilog%20%2F%20SystemVerilog-orange)
![ML](https://img.shields.io/badge/ML-scikit--learn-green)
![Course](https://img.shields.io/badge/Course-TVDC%20B.Tech%20Sem%20VI-lightgrey)

A pre-silicon security verification framework combining AMBA APB bus simulation, three stealth Hardware Trojan variants, and an unsupervised AI anomaly detection pipeline. The project demonstrates that traditional SVA-based protocol verification cannot detect semantically stealthy Trojans, and that machine learning provides a mandatory complementary detection layer.

## Project Architecture

| Layer | Technology | Role |
|---|---|---|
| RTL Design | Verilog IEEE-1364 | APB Master, infected Slaves, Trojans, Golden Reference |
| Verification | SystemVerilog (SVA, covergroups) | Protocol assertions and functional coverage |
| Simulation | ModelSim / Questa | Compile, run, log bus traces to CSV |
| AI Detection | Python + scikit-learn | Isolation Forest, One-Class SVM, Windowed IF |

## Repository Structure

```
AI-based-AMBA-Security-Verification/
├── rtl/            Verilog RTL: Master, Slaves, Trojans, Golden Reference
├── tb/             SystemVerilog: testbench, SVA assertions, coverage
├── sim/            ModelSim automation scripts
├── ai/             Python anomaly detection models
├── dataset/        Simulation trace logs (CSV) and VCD waveforms
├── results/        JSON detection metrics and PNG plots
├── scripts/        Pipeline orchestration, environment setup, analysis tools
└── docs/           In-depth guides and design documents
```

## Quick Start

**Step 1 — Initialize the Python environment**

```bash
python scripts/setup_env.py
```

Expected output: `[SUCCESS] Environment check passed. Ready to run the pipeline.`

**Step 2 — Run the hardware simulation (ModelSim / Questa)**

```tcl
cd sim/
do run_sim.do
```

Expected transcript messages:
- `[TROJAN DETECTED] Variant=A Cycle=103`
- `[TROJAN DETECTED] Variant=B Cycle=...`
- `[TROJAN DETECTED] Variant=C Cycle=...`

**Step 3 — Run the AI detection pipeline**

```bash
python scripts/run_pipeline.py
```

Results are printed as ASCII comparison tables and saved to `results/detection_results_*.json`.

## Detection Results

Results from the verified pipeline execution against all three Trojan variants:

| Trojan | Type | IF Full F1 | IF Blind F1 | SVM Full F1 | SVM Blind F1 |
|---|---|:---:|:---:|:---:|:---:|
| Variant A | 5-cond AND trigger, XOR-0xDE | 0.000 | 0.000 | 0.000 | 0.000 |
| Variant B | Counter+addr guard, 1-bit flip | 0.500 | 0.800 | 0.364 | 0.400 |
| Variant C | Sequential 3-read trigger, 0xFF | 0.500 | 0.800 | 0.364 | 0.400 |

**Note on Variant A:** The trigger requires five simultaneous conditions, giving an activation probability of approximately 1/134,217,728. The trigger did not fire in the 995-transaction trace, making detection impossible without a substantially extended simulation run.

## Key Finding

All six SVA protocol assertions pass across the entire simulation, even when a Trojan payload is active. The Trojans are fully APB-protocol compliant and never violate any timing constraint. This demonstrates why machine learning is a necessary complement to formal protocol verification for pre-silicon security assurance.

## Documentation

| Document | Description |
|---|---|
| [EVALUATION_GUIDE.md](EVALUATION_GUIDE.md) | Step-by-step command reference with expected outputs |
| [docs/FULL_PROJECT_GUIDE.md](docs/FULL_PROJECT_GUIDE.md) | Detailed beginner-friendly project walkthrough |
| [docs/TROJAN_DESIGN.md](docs/TROJAN_DESIGN.md) | Technical specification of all three Trojan variants |
| [docs/AI_PIPELINE.md](docs/AI_PIPELINE.md) | Deep dive into the ML models and feature engineering |
| [docs/VERIFICATION.md](docs/VERIFICATION.md) | SVA properties and functional coverage methodology |

## Technology Stack

- **RTL:** Verilog (IEEE 1364-2001), synthesizable, ModelSim/Questa compatible
- **Testbench:** SystemVerilog IEEE 1800-2017 with SVA, covergroups, and `$fwrite` CSV logging
- **Python:** 3.9+, pandas, numpy, scikit-learn, matplotlib, tabulate
