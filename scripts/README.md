# Automation Scripts

This directory contains the utility scripts for orchestrating the end-to-end research flow and initializing the system environment.

## 🚀 Execution Scripts

### 1. Master Pipeline (`run_pipeline.py`)
This is the main entry point for the AI analysis. It sequentially:
1.  Verifies the presence of simulation traces.
2.  Runs `anomaly_detection.py` for all 3 variants.
3.  Runs `lstm_detector.py` for sequential analysis.
4.  Consolidates all findings into a final summary report.

## 🛠️ Utility Scripts

### 1. Environment Setup (`setup_env.py` - located in Root)
Ensures that the host machine has all required Python libraries installed and ready for analysis.

### 2. VCD Extractor (`ai/extract_vcd.py`)
Provides a fallback path to extract transaction data from standard VCD waveforms if direct CSV logging is unavailable.
