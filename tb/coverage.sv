// =============================================================================
// File    : coverage.sv
// Project : AI-Assisted Stealth Hardware Trojan Detection
// Purpose : Functional coverage collector for APB bus activity.
// =============================================================================

module coverage (
    input wire        PCLK,
    input wire        PRESETn,
    input wire [7:0]  PADDR,
    input wire [7:0]  PWDATA,
    input wire        PWRITE,
    input wire        PSEL,
    input wire        PENABLE,
    input wire [7:0]  PRDATA,
    input wire        PREADY,
    input wire        trojan_active
);

    covergroup apb_coverage @(posedge PCLK iff (PRESETn && PSEL && PENABLE && PREADY));

        cp_pwrite: coverpoint PWRITE {
            bins read_trans  = {1'b0};
            bins write_trans = {1'b1};
        }

        cp_paddr: coverpoint PADDR {
            bins region_0 = {[8'h00 : 8'h1F]};
            bins region_1 = {[8'h20 : 8'h3F]};
            bins region_2 = {[8'h40 : 8'h5F]};
            bins region_3 = {[8'h60 : 8'h7F]};
            bins region_4 = {[8'h80 : 8'h9F]};
            bins region_5 = {[8'hA0 : 8'hBF]};
            bins region_6 = {[8'hC0 : 8'hDF]};
            bins region_7 = {[8'hE0 : 8'hFF]};
        }

        cp_trojan_trigger: coverpoint (PADDR == 8'hAA && PWDATA == 8'h55 && PWRITE == 1'b1) {
            bins no_trigger  = {1'b0};
            bins triggered   = {1'b1};
        }

        cp_trojan_active: coverpoint trojan_active {
            bins payload_silent = {1'b0};
            bins payload_fired  = {1'b1};
        }

        cp_pwdata: coverpoint PWDATA {
            bins trojan_data  = {8'h55};
            bins low_range    = {[8'h00:8'h3F]};
            bins mid_range    = {[8'h40:8'h7F]};
            bins high_range   = {[8'h80:8'hBF]};
            bins max_range    = {[8'hC0:8'hFF]};
        }

        cx_dir_addr: cross cp_pwrite, cp_paddr;
        cx_dir_trigger: cross cp_pwrite, cp_trojan_trigger;

    endgroup

    apb_coverage cg_apb_inst = new();

    final begin
        $display("=======================================================");
        $display("[COVERAGE] Functional Coverage Summary");
        $display("  cp_pwrite        : %0.1f%%", cg_apb_inst.cp_pwrite.get_coverage());
        $display("  cp_paddr         : %0.1f%%", cg_apb_inst.cp_paddr.get_coverage());
        $display("  cp_trojan_trigger: %0.1f%%", cg_apb_inst.cp_trojan_trigger.get_coverage());
        $display("  cp_trojan_active : %0.1f%%", cg_apb_inst.cp_trojan_active.get_coverage());
        $display("  Overall Coverage : %0.1f%%", cg_apb_inst.get_coverage());
        $display("=======================================================");
    end

endmodule
