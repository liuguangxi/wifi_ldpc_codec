//==============================================================================
// ldpcdec_core_wrapper.v
//
// Wrapper of module ldpcenc_core.
//------------------------------------------------------------------------------
// Copyright (c) 2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


`include "ldpcdec_cfg.vh"


module ldpcdec_core_wrapper (
    // System signals
    input clk,                      // system clock
    input test_i,                   // test input
    output test_o                   // test output
);

// Local signals
wire rst_n;                         // input pin
wire srst;                          // input pin
wire vld_in;                        // input pin
wire sop_in;                        // input pin
wire [3:0] mode_in;                 // input pin
wire [5:0] max_iter;                // input pin
wire sc_sel;                        // input pin
wire early_term;                    // input pin
wire [`W_IN*27-1:0] data_in;        // input pin
wire rdy_in;                        // output pin
wire vld_out;                       // output pin
wire sop_out;                       // output pin
wire eop_out;                       // output pin
wire [5:0] num_iter;                // output pin
wire pc;                            // output pin
wire [26:0] data_out;               // output pin
wire [15+`W_IN*27:0] word_o;
wire [37:0] word_i;


// Assignments
assign {rst_n, srst, vld_in, sop_in, mode_in, max_iter, sc_sel, early_term, data_in} = word_o;
assign word_i = {rdy_in, vld_out, sop_out, eop_out, num_iter, pc, data_out};


// Instances
syn_harness_in #(
    .WIDTH          (16+`W_IN*27)
) u_shi (
    .clk            (clk),
    .bit_in         (test_i),
    .word_out       (word_o)
);

syn_harness_out #(
    .WIDTH          (38)
) u_sho (
    .clk            (clk),
    .word_in        (word_i),
    .bit_out        (test_o)
);

ldpcdec_core u_ldpcdec_core (
    .clk            (clk),
    .rst_n          (rst_n),
    .srst           (srst),
    .vld_in         (vld_in),
    .sop_in         (sop_in),
    .mode_in        (mode_in),
    .max_iter       (max_iter),
    .sc_sel         (sc_sel),
    .early_term     (early_term),
    .data_in        (data_in),
    .rdy_in         (rdy_in),
    .vld_out        (vld_out),
    .sop_out        (sop_out),
    .eop_out        (eop_out),
    .num_iter       (num_iter),
    .pc             (pc),
    .data_out       (data_out)
);


endmodule
