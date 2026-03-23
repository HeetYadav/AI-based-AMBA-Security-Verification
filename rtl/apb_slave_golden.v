// =============================================================================
// Module  : apb_slave_golden
// Project : AI-Assisted Stealth Hardware Trojan Detection
// Purpose : Trojan-FREE golden reference APB slave
// =============================================================================

module apb_slave_golden (
    input  wire        PCLK,
    input  wire        PRESETn,
    input  wire [7:0]  PADDR,
    input  wire [7:0]  PWDATA,
    input  wire        PWRITE,
    input  wire        PSEL,
    input  wire        PENABLE,
    output reg  [7:0]  PRDATA,
    output wire        PREADY
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

    always @(*) begin
        if (PSEL && !PWRITE)
            PRDATA = mem[PADDR];
        else
            PRDATA = 8'h00;
    end

endmodule
