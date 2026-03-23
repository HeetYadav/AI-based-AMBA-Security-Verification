import os
import sys
import subprocess
import json
import glob
from tabulate import tabulate

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AI_DIR = os.path.join(ROOT_DIR, "ai")
RESULTS_DIR = os.path.join(ROOT_DIR, "results")

def main():
    print("=" * 70)
    print(" AI-Assisted Hardware Trojan Detection Pipeline")
    print("=" * 70)
    
    variants = ["A", "B", "C"]
    
    # 1. Run detection for all variants
    for v in variants:
        print(f"\n[PIPELINE] Analyzing Variant {v}...")
        subprocess.run([sys.executable, os.path.join(AI_DIR, "anomaly_detection.py"), "--variant", v])
        
    # 2. Consolidate results for final table
    summary_data = []
    for v in variants:
        full_path = os.path.join(RESULTS_DIR, f"detection_results_{v}_full.json")
        blind_path = os.path.join(RESULTS_DIR, f"detection_results_{v}_blind.json")
        
        if os.path.exists(full_path) and os.path.exists(blind_path):
            with open(full_path) as f: f_data = json.load(f)
            with open(blind_path) as f: b_data = json.load(f)
            
            # Use IF scores as representative
            summary_data.append([
                f"Variant {v}", 
                f"{f_data['if_f1']:.3f}", 
                f"{b_data['if_f1']:.3f}",
                "PASS" if b_data['if_f1'] > 0.5 else "FAIL (Subtle Payload)"
            ])

    print("\n" + "=" * 70)
    print(" FINAL SECURITY EVALUATION SUMMARY")
    print("=" * 70)
    
    headers = ["Variant", "Full F1 (Golden)", "Blind F1 (AI)", "Security Status"]
    print(tabulate(summary_data, headers=headers, tablefmt="fancy_grid"))
    
    print("\n[INFO] All raw data and plots are available in the results/ directory.")
    print("=" * 70)

if __name__ == "__main__":
    main()
