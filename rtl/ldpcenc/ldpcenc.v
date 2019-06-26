//==============================================================================
// ldpcenc.v
//
// Top module of Wi-Fi LDPC encoder.
//------------------------------------------------------------------------------
// Copyright (c) 2019 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


module ldpcenc (
    // System signals
    input clk,                  // system clock
    input rst_n,                // system asynchronous reset, active low
    input srst,                 // synchronous reset

    // Data interface
    input vld_in,               // input data valid
    input sop_in,               // input start of packet
    input [3:0] mode_in,        // input encoder mode, [1:0]:rate, [3:2]:codeword length
    input [26:0] data_in,       // input data
    output rdy_in,              // ready to receive input data
    output vld_out,             // output data valid
    output sop_out,             // output start of packet
    output [26:0] data_out      // output data
);

// Local signals
wire [1:0] state;
wire [3:0] mode;
wire [4:0] cnt_sym;
wire [1:0] cnt_vld;
wire [1:0] cnt_vld_max;
wire clr_acc;
wire vld;
wire [26:0] data_r1;
wire [26:0] data_r2;
wire [26:0] data_r3;


// Instances
ldpcenc_cu u_ldpcenc_cu (
    .clk            (clk),
    .rst_n          (rst_n),
    .srst           (srst),
    .vld_in         (vld_in),
    .sop_in         (sop_in),
    .mode_in        (mode_in),
    .data_in        (data_in),
    .rdy_in         (rdy_in),
    .vld_out        (vld_out),
    .sop_out        (sop_out),
    .state          (state),
    .mode           (mode),
    .cnt_sym        (cnt_sym),
    .cnt_vld        (cnt_vld),
    .cnt_vld_max    (cnt_vld_max),
    .clr_acc        (clr_acc),
    .vld            (vld),
    .data_r1        (data_r1),
    .data_r2        (data_r2),
    .data_r3        (data_r3)
);

ldpcenc_dpu u_ldpcenc_dpu (
    .clk            (clk),
    .rst_n          (rst_n),
    .state          (state),
    .mode           (mode),
    .cnt_sym        (cnt_sym),
    .cnt_vld        (cnt_vld),
    .cnt_vld_max    (cnt_vld_max),
    .clr_acc        (clr_acc),
    .vld            (vld),
    .data_r1        (data_r1),
    .data_r2        (data_r2),
    .data_r3        (data_r3),
    .data_out       (data_out)
);


endmodule
