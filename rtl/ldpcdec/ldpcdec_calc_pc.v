//==============================================================================
// ldpcdec_calc_pc.v
//
// Calculate parity check result.
//------------------------------------------------------------------------------
// Copyright (c) 2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


module ldpcdec_calc_pc (
    // System signals
    input clk,                          // system clock

    // Data interface
    input clr,                          // clear internal variables
    input [11:0] addr,                  // LUT address
    input [80:0] lq_hd_in,              // input LQ hard decision bits
    output pc_out                       // output parity check result
);

// Local signals
wire [9:0] sh1, sh2, sh3, sh4, sh5, sh6, sh7, sh8, sh9, sh10, sh11, sh12;
wire [80:0] rcs1, rcs2, rcs3, rcs4, rcs5, rcs6, rcs7, rcs8, rcs9, rcs10, rcs11, rcs12;
reg [80:0] x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12;
wire [971:0] x_all;


// Processing unit
ldpcdec_pc_tbl u_ldpcdec_pc_tbl (
    .clk            (clk),
    .addr           (addr),
    .pc_sh1         (sh1),
    .pc_sh2         (sh2),
    .pc_sh3         (sh3),
    .pc_sh4         (sh4),
    .pc_sh5         (sh5),
    .pc_sh6         (sh6),
    .pc_sh7         (sh7),
    .pc_sh8         (sh8),
    .pc_sh9         (sh9),
    .pc_sh10        (sh10),
    .pc_sh11        (sh11),
    .pc_sh12        (sh12)
);

ldpcdec_rcs u1_ldpcdec_rcs (
    .d_in           (lq_hd_in),
    .sh             (sh1[8:0]),
    .d_out          (rcs1)
);

ldpcdec_rcs u2_ldpcdec_rcs (
    .d_in           (lq_hd_in),
    .sh             (sh2[8:0]),
    .d_out          (rcs2)
);

ldpcdec_rcs u3_ldpcdec_rcs (
    .d_in           (lq_hd_in),
    .sh             (sh3[8:0]),
    .d_out          (rcs3)
);

ldpcdec_rcs u4_ldpcdec_rcs (
    .d_in           (lq_hd_in),
    .sh             (sh4[8:0]),
    .d_out          (rcs4)
);

ldpcdec_rcs u5_ldpcdec_rcs (
    .d_in           (lq_hd_in),
    .sh             (sh5[8:0]),
    .d_out          (rcs5)
);

ldpcdec_rcs u6_ldpcdec_rcs (
    .d_in           (lq_hd_in),
    .sh             (sh6[8:0]),
    .d_out          (rcs6)
);

ldpcdec_rcs u7_ldpcdec_rcs (
    .d_in           (lq_hd_in),
    .sh             (sh7[8:0]),
    .d_out          (rcs7)
);

ldpcdec_rcs u8_ldpcdec_rcs (
    .d_in           (lq_hd_in),
    .sh             (sh8[8:0]),
    .d_out          (rcs8)
);

ldpcdec_rcs u9_ldpcdec_rcs (
    .d_in           (lq_hd_in),
    .sh             (sh9[8:0]),
    .d_out          (rcs9)
);

ldpcdec_rcs u10_ldpcdec_rcs (
    .d_in           (lq_hd_in),
    .sh             (sh10[8:0]),
    .d_out          (rcs10)
);

ldpcdec_rcs u11_ldpcdec_rcs (
    .d_in           (lq_hd_in),
    .sh             (sh11[8:0]),
    .d_out          (rcs11)
);

ldpcdec_rcs u12_ldpcdec_rcs (
    .d_in           (lq_hd_in),
    .sh             (sh12[8:0]),
    .d_out          (rcs12)
);

always @(posedge clk) begin
    if (clr) begin
        x1 <= 81'd0;
        x2 <= 81'd0;
        x3 <= 81'd0;
        x4 <= 81'd0;
        x5 <= 81'd0;
        x6 <= 81'd0;
        x7 <= 81'd0;
        x8 <= 81'd0;
        x9 <= 81'd0;
        x10 <= 81'd0;
        x11 <= 81'd0;
        x12 <= 81'd0;
    end
    else begin
        if (sh1[9])    x1 <= x1 ^ rcs1;
        if (sh2[9])    x2 <= x2 ^ rcs2;
        if (sh3[9])    x3 <= x3 ^ rcs3;
        if (sh4[9])    x4 <= x4 ^ rcs4;
        if (sh5[9])    x5 <= x5 ^ rcs5;
        if (sh6[9])    x6 <= x6 ^ rcs6;
        if (sh7[9])    x7 <= x7 ^ rcs7;
        if (sh8[9])    x8 <= x8 ^ rcs8;
        if (sh9[9])    x9 <= x9 ^ rcs9;
        if (sh10[9])    x10 <= x10 ^ rcs10;
        if (sh11[9])    x11 <= x11 ^ rcs11;
        if (sh12[9])    x12 <= x12 ^ rcs12;
    end
end


// Calculate parity check result
assign x_all = {x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12};
assign pc_out = ~(|x_all);


endmodule
