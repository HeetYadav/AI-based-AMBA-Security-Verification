# AI Pipeline — Deep Dive

This document explains the three anomaly detection models used to identify Hardware Trojan activity from AMBA APB bus traces.

---

## Pipeline Flow

```
dataset/trace_log_{A,B,C}.csv
        │
        ▼  load_data()        Parse hex columns → float; fallback to sample_trace_log.csv
        │
        ▼  engineer_features()
        │   ├── addr_delta             |PADDR[t] - PADDR[t-1]|
        │   ├── read_write_ratio       Rolling 10-tx mean of (PWRITE==0)
        │   └── data_deviation_from_mean  Per-address EMA, α=0.3
        │
        ▼  StandardScaler             Zero mean, unit variance
        │
        ├──► Isolation Forest         anomaly_detection.py
        ├──► One-Class SVM            anomaly_detection.py
        └──► Windowed IF              lstm_detector.py (window=10 tx)
                │
                ▼
        results/detection_results_{variant}_{mode}.json
```

---

## Model 1: Isolation Forest

**File:** `anomaly_detection.py` | **Config:** `n_estimators=200`, `contamination=0.05`, `random_state=42`

Isolation Forest builds 200 random binary decision trees. It isolates anomalies by randomly selecting a feature and a split value. Anomalous transactions occupy sparser regions and are isolated in fewer splits (lower path length → higher anomaly score).

**Training:** Fitted exclusively on rows where `trojan_active==0 AND data_error==0` (normal transactions only).  
**Inference:** `predict(x) == -1` → anomaly; `+1` → normal.

**Feature vector (Blind Mode):** `[paddr, pwdata, prdata, pwrite, addr_delta, read_write_ratio, data_deviation_from_mean]` — 7 dimensions.  
**Feature vector (Full Mode):** Adds `data_error` column — 8 dimensions.

---

## Model 2: One-Class SVM

**File:** `anomaly_detection.py` | **Config:** `kernel="rbf"`, `ν=0.05`

OC-SVM maps training data to an RBF (Radial Basis Function) feature space and finds the smallest hypersphere enclosing the normal data. Transactions outside the sphere are flagged as anomalies.

**ν parameter:** Upper bounds the fraction of training points outside the hypersphere at 5%, directly matching the IF contamination rate. Enables side-by-side F1 comparison.

**Complementarity with IF:** IF uses axis-aligned rectangular splits; OC-SVM uses a non-linear, potentially ellipsoidal surface. They can fail independently, reducing the probability that both miss the same Trojan event simultaneously.

---

## Model 3: Windowed Isolation Forest (Sequential Detector)

**File:** `lstm_detector.py` | **Config:** Window=10 tx, `n_estimators=200`, `contamination=0.05`

Instead of scoring individual transactions, this model flattens a sliding window of 10 consecutive transactions into a single 60-dimensional vector (10 transactions × 6 features per transaction). This gives the model temporal context.

**Extra feature:** `toggle_rate` — the Hamming weight of `PWDATA[t] XOR PWDATA[t-1]`, capturing bit-flip patterns characteristic of Variant B's single-bit payload.

**Score assignment:** Each transaction inherits the **minimum** (most anomalous) score of all windows that overlap it. Threshold: 5th percentile of normal-window scores.

**Strength:** Detects Variant C's sequential trigger `0x01→0x02→0x03` even though no individual read in the sequence is anomalous in isolation.

---

## Verified Detection Results

| Trojan | IF Full F1 | IF Blind F1 | SVM Full F1 | SVM Blind F1 |
|:---:|:---:|:---:|:---:|:---:|
| Variant A | 0.000 | 0.000 | 0.000 | 0.000 |
| Variant B | 0.500 | 0.800 | 0.364 | 0.400 |
| Variant C | 0.500 | 0.800 | 0.364 | 0.400 |

> Variant A: trigger probability ≈ 1/134,217,728; never fired in 995-transaction trace.
