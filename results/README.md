# AI Detection Artifacts

This directory stores the output of the machine learning detection pipeline.

## 📁 Artifact Roadmap

### 📊 Performance Metrics (`*.json`)
Each simulation pass generates two JSON files (Full and Blind mode).
*   **Fields:** `if_f1`, `svm_f1`, `scores`, `variant`, `mode`.
*   **Usage:** Used by `run_pipeline.py` to generate the final summary.

### 🖼️ Qualitative Plots (`*.png`)
Visualizations of the detection process.
*   `plot_transactions.png`: Time-series of bus activity.
*   `plot_timeline_*.png`: Detection confidence over the course of the simulation.

### 📝 Consolidated Report
*   **`DETECTION_REPORT.md`**: A research-grade summary of the security status of the system.
