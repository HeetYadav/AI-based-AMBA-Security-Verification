# Verification Environment — `tb/`

This directory contains the SystemVerilog (IEEE 1800-2017) verification infrastructure: the top-level testbench, protocol assertion suite, and functional coverage collector.

---

## `apb_tb.sv` — Top-Level Testbench

The testbench is the integration point for the entire project. It instantiates the APB Master, the Golden Reference Slave, and one of the three infected Slave variants in parallel on the same bus.

**Key parameters:**

| Parameter | Type | Default | Description |
|---|---|---|---|
| `TROJAN_VARIANT` | `string` | `"A"` | Selects which infected slave to activate (`"A"`, `"B"`, or `"C"`) |
| `CLK_PERIOD` | `int` | `10` | Clock period in time units |

**How it works:**

1. **Clock and reset generation:** A 10-unit clock is generated; `PRESETn` is deasserted after 5 cycles.
2. **DUT instantiation:** All three Trojan variants are instantiated in a `generate` block; only the one matching `TROJAN_VARIANT` is connected to the shared bus.
3. **Golden comparison:** `data_error = PRDATA ^ PRDATA_GOLDEN` is computed combinationally each cycle.
4. **CSV logging:** An `initial` block opens the log file and writes one row per completed APB transaction (`PSEL && PENABLE && PREADY`), capturing: `cycle, paddr, pwdata, prdata, prdata_golden, pwrite, psel, penable, data_error, trojan_active`.
5. **Alerting:** `$display("[TROJAN DETECTED] Variant=%s Cycle=%0d", TROJAN_VARIANT, trans_cycle)` fires whenever `trojan_active` is high.

**Log file path:** `dataset/trace_log_{VARIANT}.csv`

---

## `assertions.sv` — SVA Protocol Checker

Six SystemVerilog concurrent properties that run against the APB bus on every rising clock edge. All properties use `disable iff (!PRESETn)` to suppress checking during reset.

| # | Property | Antecedent | Consequent |
|:---:|---|---|---|
| 1 | `p_penable_follows_psel` | `PSEL && !PENABLE` | `##1 (PSEL && PENABLE)` |
| 2 | `p_addr_stable_during_access` | `PSEL && PENABLE` | `$stable(PADDR)` |
| 3 | `p_write_data_stable` | `PSEL && PENABLE && PWRITE` | `$stable(PWDATA)` |
| 4 | `p_prdata_valid_on_read` | `PSEL && PENABLE && !PWRITE && PREADY` | `!$isunknown(PRDATA)` |
| 5 | `p_psel_stable_during_wait` | `PSEL && PENABLE && !PREADY` | `##1 PSEL` |
| 6 | `p_pready_not_unknown` | `PSEL && PENABLE` | `!$isunknown(PREADY)` |

> **Key finding:** All six properties pass across the entire simulation even when a Trojan payload is active. The Trojans are APB-protocol compliant — they do not violate any timing constraint. This rigorously demonstrates that formal protocol checking alone cannot detect semantic data corruption.

---

## `coverage.sv` — Functional Coverage

A covergroup sampled on every completed APB transaction. Measures stimulus breadth, not Trojan detection.

| Coverpoint | Bins | Purpose |
|---|---|---|
| `cp_pwrite` | `read_trans`, `write_trans` | Confirms both R/W directions exercised |
| `cp_paddr` | 8 × 32-address regions | Confirms wide address space coverage |
| `cp_trojan_trigger` | `no_trigger`, `triggered` | Confirms Variant A trigger condition was hit |
| `cp_trojan_active` | `payload_silent`, `payload_fired` | Confirms Trojan payload was observed |
| `cx_dir_addr` | 16 cross-bins | R/W direction × address region cross-coverage |

**Achieved coverage (Variant A, 995-transaction run):**
- `cp_pwrite`: 100%
- `cp_paddr`: 100%
- `cp_trojan_trigger`: 100%
- `cp_trojan_active`: 100%
- Overall cross-coverage: ~92%
