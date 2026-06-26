//==============================================================================
// ldpcdec_main_cu.v
//
// Main controller unit of Wi-Fi LDPC decoder.
//------------------------------------------------------------------------------
// Copyright (c) 2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


`include "ldpcdec_cfg.vh"


module ldpcdec_main_cu (
    // System signals
    input clk,                          // system clock
    input rst_n,                        // system asynchronous reset, active low
    input srst,                         // synchronous reset

    // Data interface
    input vld_in,                       // input data valid
    input sop_in,                       // input start of packet
    input [3:0] mode_in,                // decoder mode, [1:0]:rate, [3:2]:codeword length
    input [5:0] max_iter,               // maximum iteration, 1 - 63
    input sc_sel,                       // scaling factor for normalized min-sum
    input early_term,                   // early terminate decoding
    input [`W_IN*27-1:0] data_in,       // input LLR data
    output rdy_in,                      // ready to receive input data
    input rdy_dec,                      // ready to start decoding
    input done_dec,                     // finish decoding
    output reg [3:0] mode,              // decoder mode, [1:0]:rate, [3:2]:codeword length
    output reg [5:0] max_iter_r,        // maximum iteration, 1 - 63
    output reg sc_sel_r,                // scaling factor for normalized min-sum
    output reg early_term_r,            // early terminate decoding
    output reg init,                    // initialize variables
    output reg en_dec,                  // enable decoding
    output reg chk,                     // check decoding result
    output reg [4:0] cnt_sym,           // counter of symbol
    output reg [1:0] cnt_vld,           // counter of valid
    output reg [1:0] cnt_vld_max,       // maximum value of counter of valid
    output reg [6:0] cnt_dec,           // counter of decoding
    output reg cnt_dec_flg,             // counter of decoding flag
    output reg vld,                     // data valid
    output reg [`W_VAR*27-1:0] data_r   // sign extended data
);

// Local parameters
localparam ST_IDLE  = 2'd0;
localparam ST_LLRIN = 2'd1;
localparam ST_WAIT  = 2'd2;
localparam ST_DEC   = 2'd3;


// Local signals
reg [1:0] cs, ns;
reg [6:0] iter_main_len;
reg [6:0] iter_end_len;
wire [`W_VAR*27-1:0] data_ext;
genvar i, j;


// FSM
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cs <= ST_IDLE;
    else if (srst)
        cs <= ST_IDLE;
    else
        cs <= ns;
end

always @(*) begin
    ns = cs;
    case (cs)
        ST_IDLE: begin
            if (sop_in)    ns = ST_LLRIN;
        end
        ST_LLRIN: begin
            if (cnt_sym == 5'd23 && cnt_vld == cnt_vld_max)
                ns = (rdy_dec) ? ST_DEC : ST_WAIT;
        end
        ST_WAIT: begin
            if (rdy_dec)    ns = ST_DEC;
        end
        ST_DEC: begin
            if (done_dec)    ns = ST_IDLE;
        end
        default: ns = ST_IDLE;
    endcase
end


// Output control signals
assign rdy_in = (cs == ST_IDLE || cs == ST_LLRIN) ? 1'b1 : 1'b0;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mode <= 4'd0;
        max_iter_r <= 6'd0;
        early_term_r <= 1'b0;
        sc_sel_r <= 1'b0;
    end
    else if (cs == ST_IDLE && sop_in == 1'b1) begin
        mode <= mode_in;
        max_iter_r <= max_iter;
        early_term_r <= early_term;
        sc_sel_r <= sc_sel;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        init <= 1'b0;
    else if ((cs == ST_LLRIN || cs == ST_WAIT) && ns == ST_DEC)
        init <= 1'b1;
    else
        init <= 1'b0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        en_dec <= 1'b0;
    else if (cs == ST_DEC)
        en_dec <= 1'b1;
    else
        en_dec <= 1'b0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        iter_main_len <= 7'd0;
    else if (cs == ST_IDLE && sop_in == 1'b1) begin
        case (mode_in)
            4'b00_00: iter_main_len <= 7'd88;
            4'b00_01: iter_main_len <= 7'd87;
            4'b00_10: iter_main_len <= 7'd88;
            4'b00_11: iter_main_len <= 7'd96;
            4'b01_00: iter_main_len <= 7'd86;
            4'b01_01: iter_main_len <= 7'd87;
            4'b01_10: iter_main_len <= 7'd89;
            4'b01_11: iter_main_len <= 7'd90;
            4'b10_00: iter_main_len <= 7'd86;
            4'b10_01: iter_main_len <= 7'd87;
            4'b10_10: iter_main_len <= 7'd85;
            4'b10_11: iter_main_len <= 7'd79;
            default: iter_main_len <= 7'd0;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        iter_end_len <= 7'd0;
    else if (cs == ST_IDLE && sop_in == 1'b1) begin
        case (mode_in[1:0])
            2'd0: iter_end_len <= 7'd10;
            2'd1: iter_end_len <= 7'd14;
            2'd2: iter_end_len <= 7'd17;
            default: iter_end_len <= 7'd22;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        chk <= 1'b0;
    else if (cs == ST_DEC && cnt_dec == iter_end_len && cnt_dec_flg == 1'b1)
        chk <= 1'b1;
    else
        chk <= 1'b0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt_sym <= 5'd0;
    else if (cs == ST_LLRIN) begin
        if (vld_in == 1'b1 && cnt_vld == cnt_vld_max)
            cnt_sym <= cnt_sym + 1'b1;
    end
    else
        cnt_sym <= 5'd0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt_vld <= 2'd0;
    else if (cs == ST_LLRIN) begin
        if (vld_in)
            cnt_vld <= (cnt_vld == cnt_vld_max) ? 2'd0 : (cnt_vld + 1'b1);
    end
    else
        cnt_vld <= 2'd0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt_vld_max <= 2'd0;
    else if (cs == ST_IDLE && sop_in == 1'b1)
        cnt_vld_max <= mode_in[3:2];
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt_dec <= 7'd0;
        cnt_dec_flg <= 1'b0;
    end
    else if (cs == ST_DEC) begin
        if (cnt_dec == iter_main_len) begin
            cnt_dec <= 7'd0;
            cnt_dec_flg <= 1'b1;
        end
        else
            cnt_dec <= cnt_dec + 1'b1;
    end
    else begin
        cnt_dec <= 7'd0;
        cnt_dec_flg <= 1'b0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        vld <= 1'b0;
    else
        vld <= vld_in;
end


// Output data
generate
    for (i = 0; i < 27; i = i + 1) begin : g_data_ext
        assign data_ext[i*`W_VAR +: `W_IN] = data_in[i*`W_IN +: `W_IN];
        for (j = `W_IN; j < `W_VAR; j = j + 1) begin : g_sgn_ext
            assign data_ext[i*`W_VAR+j] = data_in[i*`W_IN+`W_IN-1];
        end
    end
endgenerate

always @(posedge clk) begin
    if (vld_in)
        data_r <= data_ext;
end


endmodule
