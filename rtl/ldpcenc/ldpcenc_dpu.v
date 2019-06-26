//==============================================================================
// ldpcenc_dpu.v
//
// Datapath unit of Wi-Fi LDPC encoder.
//------------------------------------------------------------------------------
// Copyright (c) 2019 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


module ldpcenc_dpu (
    // System signals
    input clk,                  // system clock
    input rst_n,                // system asynchronous reset, active low

    // Data interface
    input [1:0] state,          // current state
    input [3:0] mode,           // input encoder mode, [1:0]:rate, [3:2]:codeword length
    input [4:0] cnt_sym,        // counter of symbol
    input [1:0] cnt_vld,        // counter of valid
    input [1:0] cnt_vld_max,    // maximum value of counter of valid
    input clr_acc,              // clear accumulator
    input vld,                  // valid input
    input [26:0] data_r1,       // registered data 1
    input [26:0] data_r2,       // registered data 2
    input [26:0] data_r3,       // registered data 3
    output reg [26:0] data_out  // output data
);

// Local parameters
localparam ST_IDLE = 2'd0;
localparam ST_MSG  = 2'd1;
localparam ST_WAIT = 2'd2;
localparam ST_PRT  = 2'd3;


// Local signals
wire [8:0] addr;
reg [80:0] msg;
wire z54;
reg en_acc;
reg [3:0] sel_xi;
reg [1:0] sel_p0;
reg sel_pi;
wire en_pi;
reg [4:0] cnt_sym_mid;
wire [7:0] sh1, sh2, sh3, sh4, sh5, sh6, sh7, sh8, sh9, sh10, sh11, sh12;
wire [80:0] rcs1, rcs2, rcs3, rcs4, rcs5, rcs6, rcs7, rcs8, rcs9, rcs10, rcs11, rcs12;
reg [80:0] x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12;
wire [80:0] p0;
wire [80:0] p0_rsh1;
reg [80:0] xi;
wire [80:0] p0_mux, pi_mux;
reg [80:0] pi;
wire [80:0] prt;


// Control signals
assign addr = {mode, cnt_sym};

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        msg <= 81'd0;
    else if (state == ST_MSG) begin
        if (mode[3:2] == 2'd0)
            msg <= {data_r1, data_r1, data_r1};
        else if (mode[3:2] == 2'd1)
            msg <= {data_r1, data_r1, data_r2};
        else
            msg <= {data_r1, data_r2, data_r3};
    end
end

assign z54 = (mode[3:2] == 2'd1) ? 1'b1 : 1'b0;

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        en_acc <= 1'b0;
    else if (state == ST_MSG && vld == 1'b1 && cnt_vld == cnt_vld_max)
        en_acc <= 1'b1;
    else
        en_acc <= 1'b0;
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        sel_xi <= 4'd0;
    else if (state == ST_PRT) begin
        if (cnt_vld == cnt_vld_max)
            sel_xi <= cnt_sym[3:0];
    end
    else
        sel_xi <= 4'd15;
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        sel_p0 <= 2'd0;
    else if (state == ST_WAIT)
        sel_p0 <= 2'd1;
    else if (state == ST_PRT) begin
        if (cnt_vld == cnt_vld_max) begin
            if (cnt_sym == 5'd0)
                sel_p0 <= 2'd2;
            else if (cnt_sym == cnt_sym_mid)
                sel_p0 <= 2'd1;
            else
                sel_p0 <= 2'd0;
        end
    end
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        sel_pi <= 1'b0;
    else if (state == ST_PRT) begin
        if (cnt_vld == cnt_vld_max && cnt_sym != 5'd0)
            sel_pi <= 1'b1;
    end
    else
        sel_pi <= 1'b0;
end

assign en_pi = (state == ST_PRT && cnt_vld == cnt_vld_max) ? 1'b1 : 1'b0;

always @ (*) begin
    case (mode[1:0])
        2'd0: cnt_sym_mid = 5'd6;
        2'd1: cnt_sym_mid = 5'd4;
        2'd2: cnt_sym_mid = 5'd3;
        2'd3: cnt_sym_mid = 5'd2;
        default: cnt_sym_mid = 5'd6;
    endcase
end


// Processing unit
ldpcenc_tbl u_ldpcenc_tbl (
    .clk            (clk),
    .addr           (addr),
    .sh1            (sh1),
    .sh2            (sh2),
    .sh3            (sh3),
    .sh4            (sh4),
    .sh5            (sh5),
    .sh6            (sh6),
    .sh7            (sh7),
    .sh8            (sh8),
    .sh9            (sh9),
    .sh10           (sh10),
    .sh11           (sh11),
    .sh12           (sh12)
);

ldpcenc_rcs u1_ldpcenc_rcs (
    .d_in           (msg),
    .z54            (z54),
    .sh             (sh1),
    .d_out          (rcs1)
);

ldpcenc_rcs u2_ldpcenc_rcs (
    .d_in           (msg),
    .z54            (z54),
    .sh             (sh2),
    .d_out          (rcs2)
);

ldpcenc_rcs u3_ldpcenc_rcs (
    .d_in           (msg),
    .z54            (z54),
    .sh             (sh3),
    .d_out          (rcs3)
);

ldpcenc_rcs u4_ldpcenc_rcs (
    .d_in           (msg),
    .z54            (z54),
    .sh             (sh4),
    .d_out          (rcs4)
);

ldpcenc_rcs u5_ldpcenc_rcs (
    .d_in           (msg),
    .z54            (z54),
    .sh             (sh5),
    .d_out          (rcs5)
);

ldpcenc_rcs u6_ldpcenc_rcs (
    .d_in           (msg),
    .z54            (z54),
    .sh             (sh6),
    .d_out          (rcs6)
);

ldpcenc_rcs u7_ldpcenc_rcs (
    .d_in           (msg),
    .z54            (z54),
    .sh             (sh7),
    .d_out          (rcs7)
);

ldpcenc_rcs u8_ldpcenc_rcs (
    .d_in           (msg),
    .z54            (z54),
    .sh             (sh8),
    .d_out          (rcs8)
);

ldpcenc_rcs u9_ldpcenc_rcs (
    .d_in           (msg),
    .z54            (z54),
    .sh             (sh9),
    .d_out          (rcs9)
);

ldpcenc_rcs u10_ldpcenc_rcs (
    .d_in           (msg),
    .z54            (z54),
    .sh             (sh10),
    .d_out          (rcs10)
);

ldpcenc_rcs u11_ldpcenc_rcs (
    .d_in           (msg),
    .z54            (z54),
    .sh             (sh11),
    .d_out          (rcs11)
);

ldpcenc_rcs u12_ldpcenc_rcs (
    .d_in           (msg),
    .z54            (z54),
    .sh             (sh12),
    .d_out          (rcs12)
);

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
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
    else if (clr_acc) begin
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
    else if (en_acc) begin
        x1 <= x1 ^ rcs1;
        x2 <= x2 ^ rcs2;
        x3 <= x3 ^ rcs3;
        x4 <= x4 ^ rcs4;
        x5 <= x5 ^ rcs5;
        x6 <= x6 ^ rcs6;
        x7 <= x7 ^ rcs7;
        x8 <= x8 ^ rcs8;
        x9 <= x9 ^ rcs9;
        x10 <= x10 ^ rcs10;
        x11 <= x11 ^ rcs11;
        x12 <= x12 ^ rcs12;
    end
end

assign p0 = x1 ^ x2 ^ x3 ^ x4 ^ x5 ^ x6 ^ x7 ^ x8 ^ x9 ^ x10 ^ x11 ^ x12;

always @ (*) begin
    case (sel_xi)
        4'd0 : xi = x1;
        4'd1 : xi = x2;
        4'd2 : xi = x3;
        4'd3 : xi = x4;
        4'd4 : xi = x5;
        4'd5 : xi = x6;
        4'd6 : xi = x7;
        4'd7 : xi = x8;
        4'd8 : xi = x9;
        4'd9 : xi = x10;
        4'd10: xi = x11;
        4'd11: xi = x12;
        default: xi = 81'd0;
    endcase
end

assign p0_rsh1 = {p0[0], p0[80:55], ((z54) ? p0[0] : p0[54]), p0[53:1]};
assign p0_mux = (sel_p0 == 2'd0) ? 81'd0 : (sel_p0 == 2'd1) ? p0 : p0_rsh1;
assign pi_mux = (sel_pi) ? pi : 81'd0;
assign prt = p0_mux ^ pi_mux ^ xi;

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        pi <= 81'd0;
     else if (en_pi)
        pi <= prt;
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        data_out <= 27'd0;
     else if (state == ST_MSG)
        data_out <= data_r1;
    else if (state == ST_PRT) begin
        if (cnt_vld == 2'd0)
            data_out <= prt[26:0];
        else if (cnt_vld == 2'd1)
            data_out <= prt[53:27];
        else
            data_out <= prt[80:54];
    end
end


endmodule
