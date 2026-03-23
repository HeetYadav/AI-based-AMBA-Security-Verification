# Documentation

This directory contains the technical documentation for the AI-Assisted Hardware Trojan Detection project. The files are intended to be read in order from broad overview down to component-specific detail.

## Document Index

| Document | Audience | Description |
|---|---|---|
| [FULL_PROJECT_GUIDE.md](FULL_PROJECT_GUIDE.md) | All readers | Comprehensive, beginner-friendly walkthrough covering hardware, software, and AI layers |
| [TROJAN_DESIGN.md](TROJAN_DESIGN.md) | RTL / Security | Technical specification of all three Trojan variants: triggers, payloads, and stealth properties |
| [VERIFICATION.md](VERIFICATION.md) | Verification engineers | SystemVerilog verification environment, SVA property list, and functional coverage methodology |
| [AI_PIPELINE.md](AI_PIPELINE.md) | ML / Data engineers | Deep dive into the anomaly detection models, feature engineering rationale, and result interpretation |

## Reading Order

Start with `FULL_PROJECT_GUIDE.md` for an end-to-end conceptual overview. Then read `TROJAN_DESIGN.md` to understand what the AI is trying to detect, followed by `AI_PIPELINE.md` for how detection is achieved. `VERIFICATION.md` is relevant if you are extending or auditing the SystemVerilog environment.
