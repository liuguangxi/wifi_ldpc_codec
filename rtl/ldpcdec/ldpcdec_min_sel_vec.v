//==============================================================================
// ldpcdec_min_sel_vec.v
//
// Select minimum and second minimum Lq (vector unit).
//------------------------------------------------------------------------------
// Copyright (c) 2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


`include "ldpcdec_cfg.vh"


module ldpcdec_min_sel_vec (
    // System signals
    input clk,                          // system clock

    // Data interface
    input sc_sel,                       // scaling factor for normalized min-sum
    input clr,                          // clear internal variables
    input vld,                          // input valid for Lq
    input eol,                          // end of layer for Lq
    input [4:0] idx_in,                 // input index of Lq
    input [`W_VAR*81-1:0] lq_sm_in,     // input Lq in sign-magnitude format
    output [80:0] sgn_out,              // output Lq product sign
    output [404:0] min_idx_out,         // output index of minimum Lq for current layer
    output [(`W_VAR-1)*81-1:0] min_out, // output minimum Lq for current layer
    output [(`W_VAR-1)*81-1:0] min2_out // output second minimum Lq for current layer
);

// Local signals
genvar i;


// Instances
generate
    for (i = 0; i < 81; i = i + 1) begin : g_min_sel
        ldpcdec_min_sel u_ldpcdec_min_sel (
            .clk            (clk),
            .sc_sel         (sc_sel),
            .clr            (clr),
            .vld            (vld),
            .eol            (eol),
            .idx_in         (idx_in),
            .lq_sm_in       (lq_sm_in[i*`W_VAR +: `W_VAR]),
            .sgn_out        (sgn_out[i]),
            .min_idx_out    (min_idx_out[i*5 +: 5]),
            .min_out        (min_out[i*(`W_VAR-1) +: (`W_VAR-1)]),
            .min2_out       (min2_out[i*(`W_VAR-1) +: (`W_VAR-1)])
        );
    end
endgenerate


endmodule
