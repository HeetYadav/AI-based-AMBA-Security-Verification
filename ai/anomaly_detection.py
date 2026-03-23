import os
import json
import argparse
import datetime
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg") # Force non-interactive backend for server compatibility, saves to PNG
import matplotlib.pyplot as plt
from sklearn.ensemble import IsolationForest
from sklearn.svm import OneClassSVM
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import f1_score, precision_score, recall_score
from tabulate import tabulate # Used for high-quality ASCII tables

# Configuration
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DATASET_DIR = os.path.join(SCRIPT_DIR, "..", "dataset")
RESULTS_DIR = os.path.join(SCRIPT_DIR, "..", "results")
os.makedirs(RESULTS_DIR, exist_ok=True)

CONTAMINATION = 0.05
N_ESTIMATORS = 200
RANDOM_STATE = 42

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--variant", choices=["A", "B", "C"], default="A")
    parser.add_argument("--blind", action="store_true")
    return parser.parse_args()

def load_data(variant):
    path = os.path.join(DATASET_DIR, f"trace_log_{variant}.csv")
    if not os.path.exists(path):
        path = os.path.join(DATASET_DIR, "sample_trace_log.csv")
    
    df = pd.read_csv(path)
    df.columns = [c.lower() for c in df.columns]
    return df

def engineer_features(df):
    # Hex to Int conversion
    for col in ["paddr", "pwdata", "prdata", "prdata_golden", "data_error"]:
        if col in df.columns:
            df[col] = df[col].apply(lambda x: int(str(x), 16) if isinstance(x, str) else x).astype(float)
    
    # Behavioral Feature Extraction
    df["addr_delta"] = df["paddr"].diff().abs().fillna(0)
    df["read_write_ratio"] = (df["pwrite"] == 0).rolling(10, min_periods=1).mean()
    
    # Per-address deviation (The Blind Mode Key)
    addr_means = {}
    deviations = []
    for idx, row in df.iterrows():
        addr = row["paddr"]
        val = row["prdata"]
        if addr not in addr_means:
            addr_means[addr] = val
            deviations.append(0.0)
        else:
            deviations.append(abs(val - addr_means[addr]))
            addr_means[addr] = 0.7 * addr_means[addr] + 0.3 * val
    df["data_deviation_from_mean"] = deviations
    
    return df

def run_mode(df, mode_name, variant):
    blind = (mode_name == "blind")
    features = ["paddr", "pwdata", "prdata", "pwrite", "addr_delta", "read_write_ratio", "data_deviation_from_mean"]
    if not blind:
        features.extend(["data_error"])
        
    X = df[features].fillna(0).values
    y = ((df["trojan_active"] == 1) | (df["data_error"] != 0)).astype(int).values
    
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)
    X_train = X_scaled[y == 0] # Unsupervised: train on "normal"
    
    # Isolation Forest
    iso = IsolationForest(n_estimators=N_ESTIMATORS, contamination=CONTAMINATION, random_state=RANDOM_STATE)
    iso.fit(X_train)
    iso_scores = iso.score_samples(X_scaled)
    iso_pred = (iso.predict(X_scaled) == -1).astype(int)
    
    # One-Class SVM
    svm = OneClassSVM(kernel="rbf", nu=CONTAMINATION)
    svm.fit(X_train)
    svm_pred = (svm.predict(X_scaled) == -1).astype(int)
    
    results = {
        "if_f1": f1_score(y, iso_pred, zero_division=0),
        "svm_f1": f1_score(y, svm_pred, zero_division=0),
        "scores": iso_scores.tolist(),
        "variant": variant,
        "mode": mode_name
    }
    
    # Save metrics to JSON
    out_path = os.path.join(RESULTS_DIR, f"detection_results_{variant}_{mode_name}.json")
    with open(out_path, "w") as f:
        json.dump(results, f, indent=2)
        
    return results

def main():
    args = parse_args()
    df = load_data(args.variant)
    df = engineer_features(df)
    
    res_full = run_mode(df, "full", args.variant)
    res_blind = run_mode(df, "blind", args.variant)
    
    table = [
        ["Isolation Forest", f"{res_full['if_f1']:.3f}", f"{res_blind['if_f1']:.3f}"],
        ["One-Class SVM", f"{res_full['svm_f1']:.3f}", f"{res_blind['svm_f1']:.3f}"]
    ]
    
    print(f"\n[Detection Results] Variant: {args.variant}")
    print(tabulate(table, headers=["Model", "Full Mode F1", "Blind Mode F1"], tablefmt="grid"))
    print(f"[INFO] Raw metrics saved to results/")

if __name__ == "__main__":
    main()
