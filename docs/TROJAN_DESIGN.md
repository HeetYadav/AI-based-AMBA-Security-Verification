# Hardware Trojan Design Specification

This document provides the technical specification for each of the three stealth Hardware Trojan variants implemented in this project.

---

## Design Philosophy

Each Trojan variant consists of two components:

- **Trigger:** A rare condition or sequence of conditions. Designed to avoid accidental activation during standard functional simulation or assertion-based testing.
- **Payload:** The malicious action executed when the trigger fires. Implemented as a clean mux on the `PRDATA` path so all APB protocol rules remain satisfied.

All three variants are APB-protocol compliant. They produce valid, correctly-timed bus responses. No SystemVerilog assertion in `assertions.sv` can detect them.

---

## Variant A — Classic 5-Condition AND Trigger

**Module:** `rtl/stealth_trojan.v`  
**Trigger type:** Combinational (5-way AND)

**Trigger condition:**
```
PADDR     == 0xAA       (1/256 probability)
PWDATA    == 0x55       (1/256 probability)
PWRITE    == 1          (1/2   probability)
prev_addr == 0x10       (1/256 probability)
cycle_count > 200       (1/2   probability)
```

**Trigger probability:** (1/256)⁴ × (1/2)² = **1/134,217,728**

**Payload:** XOR `PRDATA` with `SECRET_KEY = 0xDE` — flips 6 of 8 data bits.

**Arm/Fire mechanism:** The trigger write sets `trojan_armed`. On the next *read* transaction, `trojan_active` asserts and the XOR payload appears. This one-cycle separation decouples cause from effect.

---

## Variant B — Temporal Guard Trigger

**Module:** `rtl/stealth_trojan_b.v`  
**Trigger type:** Transaction-counter + address

**Trigger condition:**
```
PADDR       == 0x7F           (specific address)
PWRITE      == 1              (write direction)
trans_count > 50              (after 50+ completed transactions)
```

**Payload:** XOR `PRDATA` with `SECRET_KEY_B = 0x01` — flips exactly bit[0].

**Stealth mechanism:** The transaction counter is a saturating 8-bit register incremented on every `PENABLE` assertion. Activation is impossible during any short regression test that completes before 50 transactions.

---

## Variant C — Sequential Address History Trigger

**Module:** `rtl/stealth_trojan_c.v`  
**Trigger type:** Sequential (3-deep shift register)

**Trigger condition (must occur on three consecutive reads, no interleaving):**
```
Read to 0x01, then
Read to 0x02, then
Read to 0x03
```

**Payload:** Force `PRDATA = TROJAN_PAYLOAD_C = 0xFF` — replaces all data bits with 1.

**Stealth mechanism:** Standard random testing cannot generate this exact sequence. The 3-deep address history register (`addr_hist[0:2]`) only updates on read transactions, making any intervening write transaction reset progress toward the trigger.

---

## Comparison Summary

| Property | Variant A | Variant B | Variant C |
|---|---|---|---|
| Trigger type | Combinational (5-cond) | Counter + address | Sequential (3-step history) |
| Trigger probability | ≈ 1/134,217,728 | After 50 transactions | Exact ordered read sequence |
| Payload | XOR 0xDE (6-bit corrupt) | XOR 0x01 (1-bit flip) | Replace with 0xFF |
| Passes all SVA? | Yes | Yes | Yes |
| IF Blind Mode F1 | 0.000 | 0.800 | 0.800 |
