import sys
import subprocess
from importlib.metadata import distributions

# This script ensures all required Python dependencies are installed.
# Run this once before starting the project.

REQUIRED = {
    "pandas",
    "numpy",
    "matplotlib",
    "scikit-learn",
    "tabulate"
}

def main():
    print("=" * 60)
    print(" Project Environment Initialization")
    print("=" * 60)
    
    installed = {dist.metadata['Name'].lower() for dist in distributions()}
    missing = {pkg for pkg in REQUIRED if pkg.lower() not in installed}

    if missing:
        print(f"[INFO] Installing missing dependencies: {', '.join(missing)}...")
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", *missing])
            print("[INFO] All dependencies installed successfully.")
        except Exception as e:
            print(f"[ERROR] Failed to install dependencies: {e}")
            sys.exit(1)
    else:
        print("[INFO] All dependencies are already installed.")

    print("[INFO] Checking availability...")
    try:
        import pandas
        import numpy
        import sklearn
        import matplotlib
        print("[SUCCESS] Environment check passed. Ready to run the pipeline.")
    except ImportError as e:
        print(f"[ERROR] Import check failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
