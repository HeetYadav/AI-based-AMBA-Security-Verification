# Verification Methodology — `VERIFICATION.md`

This document describes the verification strategy applied to the AMBA APB system, including the SVA assertions, functional coverage methodology, and the key finding that protocol-level verification is insufficient against semantic Hardware Trojans.

---

## Verification Layers

| Layer | Tool / Technique | What It Checks |
|---|---|---|
| Protocol Assertion | SVA (SystemVerilog Assertions) | APB timing rules and signal stability |
| Functional Coverage | Covergroups + cross-coverage | Stimulus breadth and trigger exercising |
| Golden Comparison | `data_error = PRDATA XOR PRDATA_GOLDEN` | Per-transaction semantic correctness |
| AI Anomaly Detection | Isolation Forest, OC-SVM, Windowed IF | Behavioral pattern anomalies |

---

## SVA Properties (`assertions.sv`)

Six concurrent assertions check APB protocol compliance on every rising clock edge:

| Property | What It Verifies |
|---|---|
| `p_penable_follows_psel` | `PENABLE` asserts exactly 1 cycle after `PSEL` |
| `p_addr_stable_during_access` | `PADDR` does not change during the ACCESS phase |
| `p_write_data_stable` | `PWDATA` is stable during ACCESS when writing |
| `p_prdata_valid_on_read` | `PRDATA` has no X/Z bits on a completed read |
| `p_psel_stable_during_wait` | `PSEL` remains asserted while `PREADY=0` |
| `p_pready_not_unknown` | `PREADY` is never X/Z during an active transaction |

**Key finding:** All six assertions pass across the entire simulation even when a Trojan payload is active. The Trojans produce legally-timed APB responses. Protocol checking cannot distinguish a corrupted read from a correct read.

---

## Functional Coverage (`coverage.sv`)

The `apb_coverage` covergroup samples on every completed APB transaction (`PRESETn && PSEL && PENABLE && PREADY`).

### Coverpoints

**`cp_pwrite`** — Direction coverage:
- `read_trans {1'b0}` — at least one read transaction
- `write_trans {1'b1}` — at least one write transaction

**`cp_paddr`** — Address space coverage (8 regions of 32 addresses each):
- `region_0 [0x00:0x1F]`, `region_1 [0x20:0x3F]`, ..., `region_7 [0xE0:0xFF]`
- Region 5 (`[0xA0:0xBF]`) contains Variant A trigger address `0xAA`

**`cp_trojan_trigger`** — Trigger condition coverage:
- `no_trigger {1'b0}` — normal traffic without triggering the Trojan
- `triggered {1'b1}` — exact trigger combination `PADDR==0xAA && PWDATA==0x55 && PWRITE==1`

**`cp_trojan_active`** — Payload coverage:
- `payload_silent {1'b0}` — Trojan not firing
- `payload_fired {1'b1}` — Trojan payload active

**`cx_dir_addr`** — Cross coverage: transaction direction × address region (up to 16 cross-bins)

### Achieved Results (Variant A, 995-transaction run)

| Coverpoint | Coverage |
|:---:|:---:|
| `cp_pwrite` | 100% |
| `cp_paddr` (all 8 regions) | 100% |
| `cp_trojan_trigger` | 100% |
| `cp_trojan_active` | 100% |
| `cx_dir_addr` (cross) | ~92% |

---

## The Verification Gap

Functional coverage measures *stimulus space* coverage — whether the testbench has exercised all intended scenarios. It does **not** measure whether the response to those scenarios was correct.

The table below illustrates the gap between what traditional verification can detect and what AI behavioral analysis can detect:

| Method | Variant A | Variant B | Variant C |
|---|:---:|:---:|:---:|
| SVA (protocol) | Not detected | Not detected | Not detected |
| Functional coverage | Trigger hit | Trigger hit | Trigger hit |
| IF Blind Mode | F1 = 0.000 | F1 = 0.800 | F1 = 0.800 |

**Conclusion:** Traditional pre-silicon verification is necessary but not sufficient. AI behavioral analysis — operating on transaction traces rather than protocol signals — is required to detect semantic Trojan payloads.
