//==============================================================================
// ldpcdec_calc_vn_cn.v
//
// Calculate updated LQ and Lr.
//------------------------------------------------------------------------------
// Copyright (c) 2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


`include "ldpcdec_cfg.vh"


module ldpcdec_calc_vn_cn (
    // System signals
    input clk,                          // system clock

    // Data interface
    input sgn,                          // Lq product sign for current layer
    input [4:0] min_idx,                // index of minimum Lq for current layer
    input [`W_VAR-2:0] min,             // minimum Lq for current layer
    input [`W_VAR-2:0] min2,            // second minimum Lq for current layer
    input vld,                          // input valid
    input [4:0] idx_in,                 // input index of Lq
    input [`W_VAR-1:0] lq_in,           // input Lq
    output reg [`W_VAR-1:0] lq_out,     // output LQ
    output reg [`W_CHK-1:0] lr_out      // output Lr
);

// Local parameters
localparam [`W_CHK-2:0] R_UMAX = {(`W_CHK-1){1'b1}};
localparam [`W_VAR-1:0] Q_MAX = {1'b0, {(`W_VAR-1){1'b1}}};
localparam [`W_VAR-1:0] Q_MIN = {1'b1, {(`W_VAR-2){1'b0}}, 1'b1};


// Local signals
wire lr_sgn;
wire [`W_VAR-2:0] lr_mag;
wire [`W_CHK-2:0] lr_mag_clip;
wire [`W_CHK-1:0] lr;
wire [`W_VAR:0] lq_add_lr;
wire [`W_VAR-1:0] lq_clip;


// Calculation
assign lr_sgn = sgn ^ lq_in[`W_VAR-1];
assign lr_mag = (min_idx == idx_in) ? min2 : min;

assign lr_mag_clip = (|lr_mag[`W_VAR-2:`W_CHK-1]) ? R_UMAX : lr_mag[`W_CHK-2:0];
assign lr = {lr_sgn, lr_mag_clip ^ {(`W_CHK-1){lr_sgn}}} + lr_sgn;

assign lq_add_lr = {lq_in[`W_VAR-1], lq_in} + {{2{lr_sgn}}, lr_mag ^ {(`W_VAR-1){lr_sgn}}} + lr_sgn;
assign lq_clip = (lq_add_lr[`W_VAR:`W_VAR-1] == 2'b01) ? Q_MAX :
                 ((lq_add_lr[`W_VAR:`W_VAR-1] == 2'b10) || (lq_add_lr == {2'b11, {(`W_VAR-1){1'b0}}})) ? Q_MIN :
                 lq_add_lr[`W_VAR-1:0];

always @(posedge clk) begin
    if (vld) begin
        lq_out <= lq_clip;
        lr_out <= lr;
    end
end


endmodule
