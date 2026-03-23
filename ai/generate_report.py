import os
import json
import glob
import pandas as pd

RESULTS_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "results")

def main():
    paths = glob.glob(os.path.join(RESULTS_DIR, "detection_results_*.json"))
    if not paths: return
    
    results = []
    for p in paths:
        with open(p) as f: results.append(json.load(f))
        
    df = pd.DataFrame([{"Variant": r.get("variant"), "Mode": r.get("mode"), "Model": r.get("model_used"), "F1": r.get("f1")} for r in results])
    
    with open(os.path.join(RESULTS_DIR, "DETECTION_REPORT.md"), "w") as f:
        f.write("# Detection Report\n\n")
        f.write("## Executive Summary\n\n")
        f.write(df.to_markdown(index=False))

if __name__ == "__main__": main()
