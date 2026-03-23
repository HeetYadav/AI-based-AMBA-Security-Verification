# AI Detection Pipeline — `ai/`

This directory contains the Python scripts that implement the three anomaly detection models used to identify Hardware Trojan activity from AMBA APB bus traces.

---

## Overview

The pipeline reads CSV trace logs produced by ModelSim, engineers behavioral features from raw bus signals, trains unsupervised anomaly detectors exclusively on normal traffic, and evaluates detection performance against ground-truth labels derived from the `trojan_active` simulator flag.

```
trace_log_*.csv  →  load_data()  →  engineer_features()  →  StandardScaler
                                                               ├── IsolationForest   (anomaly_detection.py)
                                                               ├── One-Class SVM     (anomaly_detection.py)
                                                               └── Windowed IF       (lstm_detector.py)
                                                                        ↓
                                                          results/detection_results_*.json
```

---

## Feature Engineering

Three behavioral features are derived from raw bus signals to give the models semantic context:

| Feature | Formula | What It Captures |
|---|---|---|
| `addr_delta` | `\|PADDR[t] - PADDR[t-1]\|` | Sudden address jumps, e.g., normal 0x00–0x1D then suddenly 0xAA |
| `read_write_ratio` | Rolling 10-tx mean of `(PWRITE==0)` | Shift in bus direction toward reads (where payloads appear) |
| `data_deviation_from_mean` | `\|PRDATA[t] - EMA_addr[t-1]\|`, α=0.3 | Per-address EMA deviation — primary Blind Mode discriminator |

In **Full Mode**, the `data_error` field (XOR of infected vs. golden slave) is added as a 4th feature, providing a near-perfect supervisory signal.

---

## Models

### 1. Isolation Forest (`anomaly_detection.py`)
**Configuration:** `n_estimators=200`, `contamination=0.05`, `random_state=42`

Isolation Forest is an ensemble of random binary decision trees. It isolates points by randomly selecting a feature and a split value. Anomalous transactions are isolated in fewer splits (shorter path length) than normal ones.

**Why chosen for this project:**
- Hardware Trojans are *rare and spatially isolated* in feature space — exactly the type of anomaly IF excels at.
- No assumption about data distribution (non-parametric).
- Scales to the 7–8 dimensional feature vector without overfitting.

**Variant-specific fit:**

| Variant | Mode | F1 | Reason |
|:---:|:---:|:---:|---|
| A | Full/Blind | 0.000 | Trigger never fired in 995-tx trace; no positive signal |
| B | Full | 0.500 | 1-bit deviation is small; catches 1 of 2 events |
| B | Blind | 0.800 | EMA deviation still detectable without golden reference |
| C | Full | 0.500 | Same pattern as Variant B |
| C | Blind | 0.800 | 0xFF payload creates large EMA spike |

---

### 2. One-Class SVM (`anomaly_detection.py`)
**Configuration:** `kernel="rbf"`, `ν=0.05`

OC-SVM maps training data to an infinite-dimensional RBF feature space and finds the smallest hypersphere enclosing the normal-data distribution.

**Why chosen as a complementary model:**
- Non-linear decision boundary captures ellipsoidal clusters that IF's axis-aligned splits can miss.
- `ν=0.05` mirrors IF contamination rate, enabling direct F1 comparison.
- Independent failure modes: flags transactions geometrically distant from any normal cluster, even when IF path-length differences are small.

**Results:** F1 = 0.364 (Full), 0.400 (Blind) for Variants B and C. Slightly lower precision than IF due to a tighter RBF boundary generating more FPs.

---

### 3. Windowed Isolation Forest / Sequential Detector (`lstm_detector.py`)
**Configuration:** Window size = 10 transactions, `n_estimators=200`, `contamination=0.05`

Instead of scoring each transaction independently, this model flattens a sliding window of 10 consecutive transactions into a single 60-dimensional feature vector, then applies Isolation Forest to the window representation.

**Why chosen:**
- Variant C requires three consecutive reads in a specific order — no single transaction in the sequence is anomalous alone. The window model captures this temporal pattern.
- Variant B's temporal guard (fires only after 50+ transactions) means the trigger always appears after a long run of normal traffic; a windowed model has stronger prior of "normal" to contrast against.
- Extra feature: `toggle_rate` (bit-flip count between successive `PWDATA` values) provides a dedicated channel for detecting Variant B's 1-bit flip payload.

**Each transaction inherits the minimum score of all windows covering it.** Threshold: 5th percentile of scores on normal-only windows.

---

## Running the Models

**Single variant, both modes:**
```bash
python ai/anomaly_detection.py --variant A
python ai/anomaly_detection.py --variant B
python ai/anomaly_detection.py --variant C
```

**Full pipeline (all variants):**
```bash
python scripts/run_pipeline.py
```

**Sequential detector:**
```bash
python ai/lstm_detector.py --variant B
```

**Output:** `results/detection_results_{variant}_{mode}.json` containing `if_f1`, `svm_f1`, and raw anomaly scores.
