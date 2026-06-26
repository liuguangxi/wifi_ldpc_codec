//==============================================================================
// ldpcdec_calc_lq_vec.v
//
// Calculate Lq (vector unit).
//------------------------------------------------------------------------------
// Copyright (c) 2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


`include "ldpcdec_cfg.vh"


module ldpcdec_calc_lq_vec (
    // System signals
    input clk,                          // system clock

    // Data interface
    input vld_lq,                       // input valid for LQ
    input [`W_VAR*81-1:0] lq_in,        // input LQ
    input vld_lr,                       // input valid for Lr
    input [`W_CHK*81-1:0] lr_in,        // input Lr
    output [`W_VAR*81-1:0] lq_tc_out,   // output Lq in two's complement format
    output [`W_VAR*81-1:0] lq_sm_out    // output Lq in sign-magnitude format
);

// Local signals
genvar i;


// Instances
generate
    for (i = 0; i < 81; i = i + 1) begin : g_calc_lq
        ldpcdec_calc_lq u_ldpcdec_calc_lq (
            .clk            (clk),
            .vld_lq         (vld_lq),
            .lq_in          (lq_in[i*`W_VAR +: `W_VAR]),
            .vld_lr         (vld_lr),
            .lr_in          (lr_in[i*`W_CHK +: `W_CHK]),
            .lq_tc_out      (lq_tc_out[i*`W_VAR +: `W_VAR]),
            .lq_sm_out      (lq_sm_out[i*`W_VAR +: `W_VAR])
        );
    end
endgenerate


endmodule
