// =============================================================================
// File    : apb_tb.sv
// Project : AI-Assisted Stealth Hardware Trojan Detection
// Purpose : Top-level SystemVerilog testbench — supports three Trojan variants.
// =============================================================================

`timescale 1ns/1ps

module apb_tb;

    parameter string TROJAN_VARIANT = "A";

    logic        PCLK;
    logic        PRESETn;

    logic [7:0]  PADDR;
    logic [7:0]  PWDATA;
    logic        PWRITE;
    logic        PSEL;
    logic        PENABLE;

    logic [7:0]  PRDATA;
    logic        PREADY;
    logic [7:0]  PRDATA_GOLDEN;
    logic        PREADY_GOLDEN;

    logic        trojan_active;
    logic [7:0]  data_error;
    logic [8:0]  cycle_count;

    initial PCLK = 1'b0;
    always #5 PCLK = ~PCLK;

    initial begin
        PRESETn = 1'b0;
        repeat (7) @(posedge PCLK);
        PRESETn = 1'b1;
        $display("[TB] Reset released. Running with TROJAN_VARIANT = %s", TROJAN_VARIANT);
    end

    apb_master u_master (
        .PCLK     (PCLK),
        .PRESETn  (PRESETn),
        .PADDR    (PADDR),
        .PWDATA   (PWDATA),
        .PWRITE   (PWRITE),
        .PSEL     (PSEL),
        .PENABLE  (PENABLE),
        .PRDATA   (PRDATA),
        .PREADY   (PREADY)
    );

    generate
        if (TROJAN_VARIANT == "A") begin : gen_slave_a
            apb_slave u_slave (.*);
        end else if (TROJAN_VARIANT == "B") begin : gen_slave_b
            apb_slave_b u_slave_b (
                .PCLK(PCLK), .PRESETn(PRESETn), .PADDR(PADDR), .PWDATA(PWDATA),
                .PWRITE(PWRITE), .PSEL(PSEL), .PENABLE(PENABLE), .cycle_count(cycle_count),
                .PRDATA(PRDATA), .PREADY(PREADY), .trojan_active(trojan_active)
            );
        end else begin : gen_slave_c
            apb_slave_c u_slave_c (
                .PCLK(PCLK), .PRESETn(PRESETn), .PADDR(PADDR), .PWDATA(PWDATA),
                .PWRITE(PWRITE), .PSEL(PSEL), .PENABLE(PENABLE), .cycle_count(cycle_count),
                .PRDATA(PRDATA), .PREADY(PREADY), .trojan_active(trojan_active)
            );
        end
    endgenerate

    apb_slave_golden u_slave_golden (
        .PCLK    (PCLK),
        .PRESETn (PRESETn),
        .PADDR   (PADDR),
        .PWDATA  (PWDATA),
        .PWRITE  (PWRITE),
        .PSEL    (PSEL),
        .PENABLE (PENABLE),
        .PRDATA  (PRDATA_GOLDEN),
        .PREADY  (PREADY_GOLDEN)
    );

    always @(posedge PCLK) begin
        if (!PRESETn) cycle_count <= 9'd0;
        else if (cycle_count < 9'd511) cycle_count <= cycle_count + 1'b1;
    end

    assign data_error = PRDATA ^ PRDATA_GOLDEN;

    // Disabled to allow compilation on free simulators without SVA/coverage flags by default
    /*
    assertions u_assertions (.*);
    coverage u_coverage (.*);
    */

    initial begin
        if (TROJAN_VARIANT == "A")      $dumpfile("../dataset/trace_A.vcd");
        else if (TROJAN_VARIANT == "B") $dumpfile("../dataset/trace_B.vcd");
        else                            $dumpfile("../dataset/trace_C.vcd");
        $dumpvars(0, apb_tb);
    end

    integer log_file;
    integer trans_cycle;

    initial begin
        if (TROJAN_VARIANT == "A")      log_file = $fopen("../dataset/trace_log_A.csv", "w");
        else if (TROJAN_VARIANT == "B") log_file = $fopen("../dataset/trace_log_B.csv", "w");
        else                            log_file = $fopen("../dataset/trace_log_C.csv", "w");

        $fwrite(log_file, "cycle,paddr,pwdata,prdata,prdata_golden,pwrite,psel,penable,data_error,trojan_active\n");
        trans_cycle = 0;
        wait (PRESETn === 1'b1);

        forever begin
            @(posedge PCLK);
            if (PRESETn && PSEL && PENABLE && PREADY) begin
                trans_cycle++;
                $fwrite(log_file, "%0d,%0h,%0h,%0h,%0h,%0b,%0b,%0b,%0h,%0b\n",
                    trans_cycle, PADDR, PWDATA, PRDATA, PRDATA_GOLDEN, PWRITE, PSEL, PENABLE, data_error, trojan_active);
                if (trojan_active) $display("[TROJAN DETECTED] Cycle=%0d", trans_cycle);
            end
        end
    end

    // Phase 4 injection for Variant C
    initial begin
        if (TROJAN_VARIANT == "C") begin
            repeat (1600) @(posedge PCLK);
            wait (PRESETn === 1'b1);

            @(posedge PCLK); #1;
            force PSEL = 1; force PWRITE = 0; force PADDR = 8'h01; force PENABLE = 0;
            @(posedge PCLK); #1; force PENABLE = 1;
            @(posedge PCLK); #1; force PENABLE = 0; force PSEL = 0;

            @(posedge PCLK); #1;
            force PSEL = 1; force PWRITE = 0; force PADDR = 8'h02; force PENABLE = 0;
            @(posedge PCLK); #1; force PENABLE = 1;
            @(posedge PCLK); #1; force PENABLE = 0; force PSEL = 0;

            @(posedge PCLK); #1;
            force PSEL = 1; force PWRITE = 0; force PADDR = 8'h03; force PENABLE = 0;
            @(posedge PCLK); #1; force PENABLE = 1;
            @(posedge PCLK); #1; force PENABLE = 0; force PSEL = 0;

            @(posedge PCLK); #1;
            force PSEL = 1; force PWRITE = 0; force PADDR = 8'h04; force PENABLE = 0;
            @(posedge PCLK); #1; force PENABLE = 1;
            @(posedge PCLK); #1; force PENABLE = 0; force PSEL = 0;

            release PSEL; release PWRITE; release PADDR; release PENABLE;
        end
    end

    final begin
        $fclose(log_file);
    end

    initial begin
        repeat (2000) @(posedge PCLK);
        $finish;
    end

endmodule
