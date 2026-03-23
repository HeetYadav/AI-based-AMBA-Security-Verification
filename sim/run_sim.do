# =============================================================================
# Script  : run_sim.do
# Project : AI-Assisted Stealth Hardware Trojan Detection
# Tool    : ModelSim / QuestaSim
# Usage   : Change directory to 'sim/', then: do run_sim.do
#
# Fix (2025): Replaced "add wave -recursive *" with explicit curated signal
#   groups. The recursive wildcard caused ModelSim to hang while enumerating
#   hundreds of internal sub-module signals. Now only the 13 most important
#   signals are shown, organised by function.
#
# Output files per pass:
#   Pass A : ../dataset/trace_A.vcd, ../dataset/trace_log_A.csv
#   Pass B : ../dataset/trace_B.vcd, ../dataset/trace_log_B.csv
#   Pass C : ../dataset/trace_C.vcd, ../dataset/trace_log_C.csv
# =============================================================================

proc run_variant { variant } {
    echo ""
    echo "============================================================"
    echo " PASS $variant - Compiling and simulating Trojan Variant $variant"
    echo "============================================================"

    # ------------------------------------------------------------------
    # Cleanly terminate any previous simulation session
    # ------------------------------------------------------------------
    quit -sim

    # Recreate work library from scratch for each pass
    if { [file exists work] } {
        vdel -lib work -all
    }
    vlib work
    vmap work work

    # ------------------------------------------------------------------
    # Compile RTL — order matters (no-dependency modules first)
    # ------------------------------------------------------------------
    echo "\[Pass $variant\] Compiling RTL..."

    vlog ../rtl/apb_slave_golden.v

    vlog ../rtl/stealth_trojan.v
    vlog ../rtl/stealth_trojan_b.v
    vlog ../rtl/stealth_trojan_c.v

    vlog ../rtl/apb_slave.v
    vlog ../rtl/apb_slave_b.v
    vlog ../rtl/apb_slave_c.v

    vlog ../rtl/apb_master.v

    echo "\[Pass $variant\] Compiling Testbench..."
    vlog -sv ../tb/apb_tb.sv
    # vlog -sv ../tb/assertions.sv   # Uncomment for Questa (SVA)
    # vlog -sv ../tb/coverage.sv     # Uncomment for Questa

    # ------------------------------------------------------------------
    # Elaborate and start simulation
    # ------------------------------------------------------------------
    echo "\[Pass $variant\] Starting simulation..."
    vsim -novopt -g TROJAN_VARIANT=$variant work.apb_tb

    # ------------------------------------------------------------------
    # Add ONLY the important waveforms — organised into labelled groups.
    #
    # WHY: "add wave -recursive *" recursively enumerates every internal
    # wire in every sub-module (LFSR bits, internal state registers, RAM
    # cells, etc.) producing 200+ signals and causing ModelSim to hang.
    # The 13 signals below are the only ones needed to verify APB
    # protocol correctness and Trojan detection.
    # ------------------------------------------------------------------

    # Group 1 - Clock and Reset (essential timing baseline)
    add wave -divider "Clock and Reset"
    add wave -label "PCLK"    sim:/apb_tb/PCLK
    add wave -label "PRESETn" sim:/apb_tb/PRESETn

    # Group 2 - APB Bus (core protocol signals driven by master)
    add wave -divider "APB Bus"
    add wave -label "PADDR"   -radix hex      sim:/apb_tb/PADDR
    add wave -label "PWDATA"  -radix hex      sim:/apb_tb/PWDATA
    add wave -label "PWRITE"                  sim:/apb_tb/PWRITE
    add wave -label "PSEL"                    sim:/apb_tb/PSEL
    add wave -label "PENABLE"                 sim:/apb_tb/PENABLE

    # Group 3 - Slave Response (what the infected slave returns)
    add wave -divider "Slave Response"
    add wave -label "PRDATA"  -radix hex      sim:/apb_tb/PRDATA
    add wave -label "PREADY"                  sim:/apb_tb/PREADY

    # Group 4 - Trojan Detection (the critical security signals)
    add wave -divider "Trojan Detection"
    add wave -label "trojan_active"           sim:/apb_tb/trojan_active
    add wave -label "data_error" -radix hex   sim:/apb_tb/data_error

    # Group 5 - Golden Reference (clean slave for golden comparison)
    add wave -divider "Golden Reference"
    add wave -label "PRDATA_GOLDEN" -radix hex sim:/apb_tb/PRDATA_GOLDEN
    add wave -label "PREADY_GOLDEN"            sim:/apb_tb/PREADY_GOLDEN

    # Group 6 - Cycle Counter (used by Variant A trigger condition)
    add wave -divider "Cycle Counter"
    add wave -label "cycle_count" -radix unsigned sim:/apb_tb/cycle_count

    # Flush the wave window so the UI does not block run -all
    update

    # ------------------------------------------------------------------
    # Run simulation to completion ($finish in testbench after 2000 cycles)
    # ------------------------------------------------------------------
    run -all

    echo ""
    echo "\[Pass $variant\] Done. CSV log: ../dataset/trace_log_$variant.csv"
    echo "------------------------------------------------------------"
}

# =============================================================================
# Execute all three variant passes sequentially
# =============================================================================
echo ""
echo "============================================================"
echo "  AI-Assisted Trojan Detection — Multi-Variant Simulation"
echo "  Variant A : 5-condition AND trigger  (XOR key 0xDE)"
echo "  Variant B : Transaction-count guard  (1-bit flip)"
echo "  Variant C : Sequential address hist  (payload 0xFF)"
echo "============================================================"

run_variant A
run_variant B
run_variant C

echo ""
echo "============================================================"
echo "  All three variant simulations complete."
echo "  Generated CSV dataset files:"
echo "    ../dataset/trace_log_A.csv"
echo "    ../dataset/trace_log_B.csv"
echo "    ../dataset/trace_log_C.csv"
echo ""
echo "  Next step: cd .. && python ai/anomaly_detection.py"
echo "============================================================"
echo ""
