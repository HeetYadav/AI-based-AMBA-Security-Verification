// =============================================================================
// File    : assertions.sv
// Project : AI-Assisted Stealth Hardware Trojan Detection
// Purpose : SystemVerilog Assertion (SVA) checker for AMBA APB protocol rules.
// =============================================================================

module assertions (
    input wire        PCLK,
    input wire        PRESETn,
    input wire [7:0]  PADDR,
    input wire [7:0]  PWDATA,
    input wire        PWRITE,
    input wire        PSEL,
    input wire        PENABLE,
    input wire [7:0]  PRDATA,
    input wire        PREADY
);

    property p_penable_follows_psel;
        @(posedge PCLK) disable iff (!PRESETn)
        (PSEL && !PENABLE) |-> ##1 (PSEL && PENABLE);
    endproperty
    assert property (p_penable_follows_psel);
    cover property (p_penable_follows_psel);

    property p_addr_stable_during_access;
        @(posedge PCLK) disable iff (!PRESETn)
        (PSEL && PENABLE) |-> ($stable(PADDR));
    endproperty
    assert property (p_addr_stable_during_access);
    cover property (p_addr_stable_during_access);

    property p_write_data_stable;
        @(posedge PCLK) disable iff (!PRESETn)
        (PSEL && PENABLE && PWRITE) |-> ($stable(PWDATA));
    endproperty
    assert property (p_write_data_stable);
    cover property (p_write_data_stable);

    property p_psel_low_without_transaction;
        @(posedge PCLK) disable iff (!PRESETn)
        (!PSEL) |-> (!PENABLE);
    endproperty
    assert property (p_psel_low_without_transaction);
    cover property (p_psel_low_without_transaction);

    property p_prdata_valid_on_read;
        @(posedge PCLK) disable iff (!PRESETn)
        (PSEL && PENABLE && !PWRITE && PREADY) |-> (!$isunknown(PRDATA));
    endproperty
    assert property (p_prdata_valid_on_read);
    cover property (p_prdata_valid_on_read);

    property p_pwrite_stable;
        @(posedge PCLK) disable iff (!PRESETn)
        (PSEL && PENABLE) |-> ($stable(PWRITE));
    endproperty
    assert property (p_pwrite_stable);
    cover property (p_pwrite_stable);

endmodule
