//==============================================================================
// ldpcdec_calc_vn_cn_vec.v
//
// Calculate updated LQ and Lr (vector unit).
//------------------------------------------------------------------------------
// Copyright (c) 2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


`include "ldpcdec_cfg.vh"


module ldpcdec_calc_vn_cn_vec (
    // System signals
    input clk,                          // system clock

    // Data interface
    input [80:0] sgn,                   // Lq product sign for current layer
    input [404:0] min_idx,              // index of minimum Lq for current layer
    input [(`W_VAR-1)*81-1:0] min,      // minimum Lq for current layer
    input [(`W_VAR-1)*81-1:0] min2,     // second minimum Lq for current layer
    input vld,                          // input valid
    input [4:0] idx_in,                 // input index of Lq
    input [`W_VAR*81-1:0] lq_in,        // input Lq
    output [`W_VAR*81-1:0] lq_out,      // output LQ
    output [`W_CHK*81-1:0] lr_out       // output Lr
);

// Local signals
genvar i;


// Instances
generate
    for (i = 0; i < 81; i = i + 1) begin : g_calc_vn_cn
        ldpcdec_calc_vn_cn u_ldpcdec_calc_vn_cn (
            .clk            (clk),
            .sgn            (sgn[i]),
            .min_idx        (min_idx[i*5 +: 5]),
            .min            (min[i*(`W_VAR-1) +: (`W_VAR-1)]),
            .min2           (min2[i*(`W_VAR-1) +: (`W_VAR-1)]),
            .vld            (vld),
            .idx_in         (idx_in),
            .lq_in          (lq_in[i*`W_VAR +: `W_VAR]),
            .lq_out         (lq_out[i*`W_VAR +: `W_VAR]),
            .lr_out         (lr_out[i*`W_CHK +: `W_CHK])
        );
    end
endgenerate


endmodule
