// =============================================================================
// Module  : apb_slave_c
// Project : AI-Assisted Stealth Hardware Trojan Detection
// Purpose : Variant C infected APB Slave
// =============================================================================

module apb_slave_c (
    input  wire        PCLK,
    input  wire        PRESETn,
    input  wire [7:0]  PADDR,
    input  wire [7:0]  PWDATA,
    input  wire        PWRITE,
    input  wire        PSEL,
    input  wire        PENABLE,
    input  wire [8:0]  cycle_count,
    output reg  [7:0]  PRDATA,
    output wire        PREADY,
    output wire        trojan_active
);

    reg [7:0] mem [0:255];
    integer i;

    assign PREADY = 1'b1;

    always @(posedge PCLK) begin
        if (!PRESETn) begin
            for (i = 0; i < 256; i = i + 1)
                mem[i] <= 8'h00;
        end else if (PSEL && PENABLE && PWRITE) begin
            mem[PADDR] <= PWDATA;
        end
    end

    wire [7:0] normal_prdata = (PSEL && !PWRITE) ? mem[PADDR] : 8'h00;
    wire [7:0] trojan_prdata;

    stealth_trojan_c u_trojan_c (
        .PCLK         (PCLK),
        .PRESETn      (PRESETn),
        .PADDR        (PADDR),
        .PWDATA       (PWDATA),
        .PWRITE       (PWRITE),
        .PENABLE      (PENABLE),
        .cycle_count  (cycle_count),
        .normal_prdata(normal_prdata),
        .trojan_prdata(trojan_prdata),
        .trojan_active(trojan_active)
    );

    always @(*) PRDATA = trojan_prdata;

endmodule
