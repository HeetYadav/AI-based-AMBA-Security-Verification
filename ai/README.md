# AI Detection Pipeline

This directory contains the Python scripts that implement the three anomaly detection models used to identify Hardware Trojan activity from AMBA APB bus traces.

## Pipeline Overview

```
dataset/trace_log_*.csv
        |
        v
load_and_engineer()   [Feature extraction from raw bus signals]
        |
        v
StandardScaler        [Zero-mean, unit-variance normalization]
        |
        +----> IsolationForest   (anomaly_detection.py)
        |
        +----> One-Class SVM     (anomaly_detection.py)
        |
        +----> Windowed IF       (lstm_detector.py)
                 |
                 v
        results/detection_results_*.json
```

The models are trained exclusively on normal traffic rows, then evaluated against the full trace including Trojan-active transactions. Ground-truth labels are derived from the `trojan_active` flag written by the testbench.

## Feature Engineering

Three behavioral features are derived from raw bus signals to give the models semantic context beyond raw signal values:

| Feature | Formula | What It Captures |
|---|---|---|
| `addr_delta` | `\|PADDR[t] - PADDR[t-1]\|` | Sudden address jumps (e.g., normal 0x00–0x1D then suddenly 0xAA) |
| `read_write_ratio` | Rolling 10-tx mean of `(PWRITE==0)` | Shifts in bus direction toward reads, where payloads appear |
| `data_deviation_from_mean` | `\|PRDATA[t] - EMA_addr[t-1]\|`, α=0.3 | Per-address EMA deviation — the primary Blind Mode discriminator |

In Full Mode, the `data_error` field (XOR of infected vs. golden slave output) is added as a fourth feature, providing a near-perfect supervisory signal.

## Models

### Isolation Forest (`anomaly_detection.py`)

**Configuration:** `n_estimators=200`, `contamination=0.05`, `random_state=42`

Isolation Forest is an ensemble of random binary decision trees. It isolates anomalous points by randomly selecting features and split values. Anomalous transactions are isolated in fewer splits (shorter path length) than normal ones.

Why it suits this problem:
- Hardware Trojans are rare and spatially isolated in feature space, exactly where IF excels.
- No distributional assumptions required (non-parametric).
- Scales cleanly to the 7–8 dimensional feature vector without overfitting.

**Per-variant results:**

| Variant | Mode | F1 | Reason |
|:---:|:---:|:---:|---|
| A | Full/Blind | 0.000 | Trigger never fired in 995-tx trace; no positive ground-truth labels |
| B | Full | 0.500 | 1-bit deviation is small; catches 1 of 2 events |
| B | Blind | 0.800 | EMA deviation remains detectable without golden reference |
| C | Full | 0.500 | Same pattern as Variant B |
| C | Blind | 0.800 | 0xFF payload creates a large EMA spike |

### One-Class SVM (`anomaly_detection.py`)

**Configuration:** `kernel="rbf"`, `ν=0.05`

OC-SVM maps training data to an infinite-dimensional RBF feature space and finds the smallest hypersphere enclosing the normal data distribution. It provides a complementary model whose failure modes differ from IF:
- Non-linear boundary captures ellipsoidal clusters that IF's axis-aligned splits can miss.
- `ν=0.05` mirrors IF contamination rate for direct F1 comparison.
- Flags transactions geometrically distant from any normal cluster, even when path-length differences are small.

Results: F1 = 0.364 (Full), 0.400 (Blind) for Variants B and C. Slightly lower precision than IF due to a tighter RBF boundary generating more false positives.

### Windowed Isolation Forest (`lstm_detector.py`)

**Configuration:** Window size = 10 transactions, `n_estimators=200`, `contamination=0.05`

Instead of scoring each transaction independently, this model flattens a sliding window of 10 consecutive transactions into a single 60-dimensional feature vector, then applies Isolation Forest on the window representation.

Why it is useful:
- Variant C requires three consecutive reads in a specific order. No single transaction in the sequence is anomalous alone. The window model captures this temporal dependency.
- Variant B's temporal guard (fires only after 50+ completed transactions) means the trigger always appears after a long normal run; the windowed model has a stronger contrast baseline.
- A dedicated `toggle_rate` feature (bit-flip count between successive `PWDATA` values) provides an extra channel for detecting Variant B's single-bit flip payload.

Each transaction inherits the minimum anomaly score across all windows that contain it. The anomaly threshold is the 5th percentile of scores computed on normal-only windows.

## Usage

Run a single variant through both detection modes:

```bash
python ai/anomaly_detection.py --variant A
python ai/anomaly_detection.py --variant B
python ai/anomaly_detection.py --variant C
```

Run the full pipeline across all variants:

```bash
python scripts/run_pipeline.py
```

Run the sequential windowed detector:

```bash
python ai/lstm_detector.py --variant B
```

Output files are written to `results/detection_results_{variant}_{mode}.json` and contain `if_f1`, `svm_f1`, per-transaction anomaly scores, and metadata.
