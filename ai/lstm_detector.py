import os
import argparse
import numpy as np
import pandas as pd
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import StandardScaler
import matplotlib.pyplot as plt

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DATASET_DIR = os.path.join(SCRIPT_DIR, "..", "dataset")
PLOT_DIR = SCRIPT_DIR

WINDOW_SIZE = 10
N_ESTIMATORS = 200
CONTAMINATION = 0.05
RANDOM_STATE = 42
STEP_FEATURES = ["paddr", "pwdata", "prdata", "pwrite", "addr_delta", "toggle_rate"]

def load_data(variant):
    candidates = [
        os.path.join(DATASET_DIR, f"trace_log_{variant}.csv"),
        os.path.join(DATASET_DIR, "trace_log.csv"),
        os.path.join(DATASET_DIR, "sample_trace_log.csv"),
    ]
    for path in candidates:
        if os.path.exists(path):
            df = pd.read_csv(path)
            df.columns = [c.lower() for c in df.columns]
            for col in ["paddr", "pwdata", "prdata", "prdata_golden", "data_error"]:
                if col in df.columns:
                    df[col] = df[col].apply(lambda x: int(str(x), 16) if isinstance(x, str) else x).astype(float)
            if "addr_delta" not in df.columns: df["addr_delta"] = df["paddr"].diff().abs().fillna(0)
            if "toggle_rate" not in df.columns:
                df["toggle_rate"] = ((df["pwdata"].shift(1).fillna(0).astype(int) ^ df["pwdata"].astype(int)).apply(lambda x: bin(x).count("1") / 8))
            return df
    exit(1)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--variant", choices=["A", "B", "C"], default="A")
    args = parser.parse_args()
    
    df = load_data(args.variant)
    y = ((df.get("trojan_active", pd.Series(np.zeros(len(df)))).astype(int) == 1) | (df.get("data_error", pd.Series(np.zeros(len(df)))).astype(float) != 0)).astype(int).values
    
    n = len(df)
    avail = [c for c in STEP_FEATURES if c in df.columns]
    X_all = df[avail].fillna(0).values
    n_windows = n - WINDOW_SIZE + 1
    
    if n_windows < 1: exit(1)
    
    windows = np.zeros((n_windows, WINDOW_SIZE * len(avail)))
    for i in range(n_windows): windows[i] = X_all[i:i + WINDOW_SIZE].flatten()
    
    window_trojan = np.array([int(y[i:i+WINDOW_SIZE].sum() > 0) for i in range(n_windows)])
    W_normal = windows[window_trojan == 0]
    if len(W_normal) < 5: W_normal = windows
    
    scaler = StandardScaler()
    W_all_scaled = scaler.fit_transform(windows)
    W_normal_scaled = scaler.transform(W_normal)
    
    model = IsolationForest(n_estimators=N_ESTIMATORS, contamination=CONTAMINATION, random_state=RANDOM_STATE)
    model.fit(W_normal_scaled)
    window_scores = model.score_samples(W_all_scaled)
    
    per_trans = np.full(n, fill_value=np.inf)
    for i, score in enumerate(window_scores):
        for j in range(i, min(i + WINDOW_SIZE, n)):
            if score < per_trans[j]: per_trans[j] = score
    per_trans[per_trans == np.inf] = 0.0
    
    baseline_scores = IsolationForest(n_estimators=N_ESTIMATORS, contamination=CONTAMINATION, random_state=RANDOM_STATE).fit(scaler.fit_transform(X_all[y==0])).score_samples(scaler.fit_transform(X_all))
    
    lstm_first = np.where(per_trans < np.percentile(per_trans[y==0], 5))[0]
    if_first = np.where(baseline_scores < np.percentile(baseline_scores[y==0], 5))[0]
    
    print(f"Variant {args.variant} LSTM First Detection Cycle: {lstm_first[0] if len(lstm_first) else 0}")
    print(f"Variant {args.variant} IF First Detection Cycle: {if_first[0] if len(if_first) else 0}")

if __name__ == "__main__":
    main()
