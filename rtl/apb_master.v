// =============================================================================
// Module  : apb_master
// Project : AI-Assisted Stealth Hardware Trojan Detection
// Purpose : AMBA APB Master implementing a 3-state FSM (IDLE → SETUP → ACCESS)
// =============================================================================

module apb_master (
    input  wire        PCLK,
    input  wire        PRESETn,
    output reg  [7:0]  PADDR,
    output reg  [7:0]  PWDATA,
    output reg         PWRITE,
    output reg         PSEL,
    output reg         PENABLE,
    input  wire [7:0]  PRDATA,
    input  wire        PREADY
);

    localparam  IDLE    = 2'b00,
                SETUP   = 2'b01,
                ACCESS  = 2'b10;

    reg [1:0]  state, next_state;

    reg [8:0]   cycle_count;
    reg [7:0]   trans_count;
    reg [7:0]   next_addr;
    reg [7:0]   next_data;
    reg         next_write;
    reg [15:0]  lfsr;

    localparam PHASE_NORM_WR  = 2'd0,
               PHASE_NORM_RD  = 2'd1,
               PHASE_RANDOM   = 2'd2,
               PHASE_TROJAN   = 2'd3,
               PHASE_SEQ_RD   = 2'd4; // Variant C Trigger phase

    reg [2:0]  phase;
    reg [7:0]  phase_cnt;

    // PRNG (Galois 16-bit)
    always @(posedge PCLK) begin
        if (!PRESETn) lfsr <= 16'hACE1;
        else          lfsr <= {1'b0, lfsr[15:1]} ^ (lfsr[0] ? 16'hB400 : 16'h0000);
    end

    // Cycle Counter
    always @(posedge PCLK) begin
        if (!PRESETn) cycle_count <= 9'd0;
        else if (cycle_count < 9'd511) cycle_count <= cycle_count + 1'b1;
    end

    // Phase Controller
    always @(posedge PCLK) begin
        if (!PRESETn) begin
            phase <= PHASE_NORM_WR;
            phase_cnt <= 8'd0;
            trans_count <= 8'd0;
        end else if (state == ACCESS && PREADY) begin
            trans_count <= trans_count + 1'b1;
            phase_cnt <= phase_cnt + 1'b1;
            case (phase)
                PHASE_NORM_WR : if (phase_cnt == 8'd29) begin phase <= PHASE_NORM_RD; phase_cnt <= 0; end
                PHASE_NORM_RD : if (phase_cnt == 8'd29) begin phase <= PHASE_RANDOM; phase_cnt <= 0; end
                PHASE_RANDOM  : if (phase_cnt == 8'd39) begin phase <= PHASE_TROJAN; phase_cnt <= 0; end
                PHASE_TROJAN  : if (phase_cnt == 8'd9)  begin phase <= PHASE_SEQ_RD; phase_cnt <= 0; end
                PHASE_SEQ_RD  : if (phase_cnt == 8'd9)  begin /* done */ end
            endcase
        end
    end

    // Transaction Staging
    always @(*) begin
        next_addr  = 8'h00; next_data  = 8'h00; next_write = 1'b0;
        case (phase)
            PHASE_NORM_WR: begin next_addr=phase_cnt; next_data=phase_cnt+8'h10; next_write=1'b1; end
            PHASE_NORM_RD: begin next_addr=phase_cnt; next_data=8'h00; next_write=1'b0; end
            PHASE_RANDOM:  begin next_addr=lfsr[7:0]; next_data=lfsr[15:8]; next_write=lfsr[0]; end
            PHASE_TROJAN: begin
                // Variant A trigger
                case (phase_cnt)
                    8'd0: begin next_addr=8'h10; next_data=8'hFF; next_write=1'b1; end
                    8'd1, 8'd2, 8'd3, 8'd4, 8'd5: begin next_addr=8'h20; next_write=1'b0; end
                    8'd6: begin next_addr=8'hAA; next_data=8'h55; next_write=1'b1; end
                    default: begin next_addr=lfsr[7:0]; next_write=1'b0; end
                endcase
            end
            PHASE_SEQ_RD: begin
                // Variant C Trigger (3 consecutive reads to 0x01, 0x02, 0x03)
                case (phase_cnt)
                    8'd0: begin next_addr=8'h01; next_write=1'b0; end
                    8'd1: begin next_addr=8'h02; next_write=1'b0; end
                    8'd2: begin next_addr=8'h03; next_write=1'b0; end
                    8'd3: begin next_addr=8'h04; next_write=1'b0; end // Observation read
                    default: begin next_addr=lfsr[7:0]; next_write=1'b0; end
                endcase
            end
        endcase
    end

    // FSM
    always @(posedge PCLK) begin
        if (!PRESETn) state <= IDLE;
        else          state <= next_state;
    end

    always @(*) begin
        case (state)
            IDLE   : next_state = SETUP;
            SETUP  : next_state = ACCESS;
            ACCESS : next_state = (PREADY) ? SETUP : ACCESS;
            default: next_state = IDLE;
        endcase
    end

    always @(posedge PCLK) begin
        if (!PRESETn) begin
            PSEL <= 0; PENABLE <= 0; PADDR <= 0; PWDATA <= 0; PWRITE <= 0;
        end else begin
            case (state)
                IDLE: begin PSEL <= 0; PENABLE <= 0; end
                SETUP: begin PSEL <= 1; PENABLE <= 0; PADDR <= next_addr; PWDATA <= next_data; PWRITE <= next_write; end
                ACCESS: PENABLE <= 1;
            endcase
        end
    end
endmodule
