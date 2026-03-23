"""
compute_report_values.py
Computes all the empirical values needed to update the LaTeX report:
  - Confusion matrices (TP, TN, FP, FN) for all 6 variant/mode combos
  - Detection rates for Figure 5 bar chart
  - Feature mean separation (normal vs anomaly) for blind mode feature importance
  - Address coverage stats
"""
import json, os
import numpy as np
import pandas as pd
from sklearn.ensemble import IsolationForest
from sklearn.svm import OneClassSVM
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import (f1_score, precision_score, recall_score,
                             confusion_matrix)

DATASET_DIR = "dataset"
CONTAMINATION = 0.05
N_ESTIMATORS = 200
RANDOM_STATE = 42

def load_and_engineer(variant):
    path = os.path.join(DATASET_DIR, f"trace_log_{variant}.csv")
    if not os.path.exists(path):
        path = os.path.join(DATASET_DIR, "sample_trace_log.csv")
    df = pd.read_csv(path)
    df.columns = [c.lower() for c in df.columns]
    for col in ["paddr","pwdata","prdata","prdata_golden","data_error"]:
        if col in df.columns:
            df[col] = df[col].apply(lambda x: int(str(x),16) if isinstance(x,str) else x).astype(float)
    df["addr_delta"]       = df["paddr"].diff().abs().fillna(0)
    df["read_write_ratio"] = (df["pwrite"]==0).rolling(10,min_periods=1).mean()
    addr_means={}; deviations=[]
    for _,row in df.iterrows():
        addr,val = row["paddr"], row["prdata"]
        if addr not in addr_means:
            addr_means[addr]=val; deviations.append(0.0)
        else:
            deviations.append(abs(val-addr_means[addr]))
            addr_means[addr]=0.7*addr_means[addr]+0.3*val
    df["data_deviation_from_mean"] = deviations
    return df

def run_and_report(df, variant, mode):
    blind = (mode == "blind")
    features = ["paddr","pwdata","prdata","pwrite","addr_delta",
                "read_write_ratio","data_deviation_from_mean"]
    if not blind:
        features.append("data_error")
    X = df[features].fillna(0).values
    y = ((df["trojan_active"]==1)|(df["data_error"]!=0)).astype(int).values

    scaler = StandardScaler()
    Xs = scaler.fit_transform(X)
    Xt = Xs[y==0]

    iso = IsolationForest(n_estimators=N_ESTIMATORS, contamination=CONTAMINATION, random_state=RANDOM_STATE)
    iso.fit(Xt)
    ip = (iso.predict(Xs)==-1).astype(int)

    svm = OneClassSVM(kernel="rbf", nu=CONTAMINATION)
    svm.fit(Xt)
    sp = (svm.predict(Xs)==-1).astype(int)

    tn,fp,fn,tp = confusion_matrix(y, ip, labels=[0,1]).ravel()
    sttn,stfp,stfn,sttp = confusion_matrix(y, sp, labels=[0,1]).ravel()

    total = len(y); pos = int(y.sum())
    # "detection rate" = recall of positive class
    recall_if  = tp/(tp+fn) if (tp+fn)>0 else 0
    recall_svm = sttp/(sttp+stfn) if (sttp+stfn)>0 else 0

    return {
        "variant": variant, "mode": mode,
        "n_total": total, "n_trojan": pos, "n_normal": total-pos,
        "if_tp":int(tp),"if_tn":int(tn),"if_fp":int(fp),"if_fn":int(fn),
        "if_f1": round(f1_score(y,ip,zero_division=0),3),
        "if_prec": round(precision_score(y,ip,zero_division=0),3),
        "if_rec": round(recall_score(y,ip,zero_division=0),3),
        "svm_tp":int(sttp),"svm_tn":int(sttn),"svm_fp":int(stfp),"svm_fn":int(stfn),
        "svm_f1": round(f1_score(y,sp,zero_division=0),3),
        "svm_prec": round(precision_score(y,sp,zero_division=0),3),
        "svm_rec": round(recall_score(y,sp,zero_division=0),3),
        "detect_rate_if":  round(recall_if*100,1),
        "detect_rate_svm": round(recall_svm*100,1),
    }

def feature_separation(df):
    """Mean of each feature for normal vs trojan rows."""
    y = ((df["trojan_active"]==1)|(df["data_error"]!=0)).astype(int)
    feats = ["addr_delta","read_write_ratio","data_deviation_from_mean"]
    print("\n=== Feature Separation (Normal vs Trojan) ===")
    print(f"{'Feature':<30} {'Normal Mean':>12} {'Trojan Mean':>12} {'Ratio':>8}")
    for f in feats:
        nm = df.loc[y==0, f].mean()
        tm = df.loc[y==1, f].mean() if y.sum()>0 else float('nan')
        ratio = tm/nm if nm!=0 and not np.isnan(tm) else float('nan')
        print(f"{f:<30} {nm:>12.4f} {tm:>12.4f} {ratio:>8.2f}x")

def address_coverage(df):
    """How many of the 8 address bins are hit?"""
    bins = [(0x00,0x1F),(0x20,0x3F),(0x40,0x5F),(0x60,0x7F),
            (0x80,0x9F),(0xA0,0xBF),(0xC0,0xDF),(0xE0,0xFF)]
    addrs = df["paddr"].values
    hit = sum(1 for lo,hi in bins if any((addrs>=lo)&(addrs<=hi)))
    print(f"\n=== Address Coverage ===")
    print(f"Bins hit: {hit}/8 = {hit/8*100:.1f}%")
    for i,(lo,hi) in enumerate(bins):
        count = ((addrs>=lo)&(addrs<=hi)).sum()
        print(f"  Region {i}: 0x{lo:02X}-0x{hi:02X}: {count} transactions")

print("=" * 60)
for variant in ["A","B","C"]:
    df = load_and_engineer(variant)
    print(f"\n{'='*60}")
    print(f"VARIANT {variant}  (n={len(df)}, trojan rows={int(((df['trojan_active']==1)|(df['data_error']!=0)).sum())})")
    for mode in ["full","blind"]:
        r = run_and_report(df, variant, mode)
        print(f"\n  Mode={mode.upper()}")
        print(f"    IF:  F1={r['if_f1']}, P={r['if_prec']}, R={r['if_rec']}, "
              f"TP={r['if_tp']}, TN={r['if_tn']}, FP={r['if_fp']}, FN={r['if_fn']}, "
              f"DetRate={r['detect_rate_if']}%")
        print(f"    SVM: F1={r['svm_f1']}, P={r['svm_prec']}, R={r['svm_rec']}, "
              f"TP={r['svm_tp']}, TN={r['svm_tn']}, FP={r['svm_fp']}, FN={r['svm_fn']}, "
              f"DetRate={r['detect_rate_svm']}%")
    feature_separation(df)
    address_coverage(df)
