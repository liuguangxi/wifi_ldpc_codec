//==============================================================================
// ldpcdec_calc_lq.v
//
// Calculate Lq.
//------------------------------------------------------------------------------
// Copyright (c) 2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


`include "ldpcdec_cfg.vh"


module ldpcdec_calc_lq (
    // System signals
    input clk,                          // system clock

    // Data interface
    input vld_lq,                       // input valid for LQ
    input [`W_VAR-1:0] lq_in,           // input LQ
    input vld_lr,                       // input valid for Lr
    input [`W_CHK-1:0] lr_in,           // input Lr
    output reg [`W_VAR-1:0] lq_tc_out,  // output Lq in two's complement format
    output reg [`W_VAR-1:0] lq_sm_out   // output Lq in sign-magnitude format
);

// Local parameters
localparam [`W_VAR-1:0] Q_MAX = {1'b0, {(`W_VAR-1){1'b1}}};
localparam [`W_VAR-1:0] Q_MIN = {1'b1, {(`W_VAR-2){1'b0}}, 1'b1};


// Local signals
wire [`W_VAR:0] lq_ext;
wire [`W_VAR:0] lr_ext;
wire [`W_VAR:0] lq_sub_lr;
wire [`W_VAR-1:0] lq_clip;
wire lq_sgn;
wire [`W_VAR-2:0] lq_mag;


// Calculation
assign lq_ext = {lq_in[`W_VAR-1], lq_in};
assign lr_ext = (vld_lr) ? {{(`W_VAR-`W_CHK+1){lr_in[`W_CHK-1]}}, lr_in} : `W_VAR'd0;
assign lq_sub_lr = lq_ext - lr_ext;

assign lq_clip = (lq_sub_lr[`W_VAR:`W_VAR-1] == 2'b01) ? Q_MAX :
                 ((lq_sub_lr[`W_VAR:`W_VAR-1] == 2'b10) || (lq_sub_lr == {2'b11, {(`W_VAR-1){1'b0}}})) ? Q_MIN :
                 lq_sub_lr[`W_VAR-1:0];

assign lq_sgn = lq_sub_lr[`W_VAR];
assign lq_mag = ({(`W_VAR-1){lq_clip[`W_VAR-1]}} ^ lq_clip[`W_VAR-2:0]) + lq_clip[`W_VAR-1];

always @(posedge clk) begin
    if (vld_lq) begin
        lq_tc_out <= lq_clip;
        lq_sm_out <= {lq_sgn, lq_mag};
    end
end


endmodule
