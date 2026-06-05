//==============================================================================
// wf8ldpcenc_dpu.v
//
// Datapath unit of Wi-Fi 8 LDPC encoder.
//------------------------------------------------------------------------------
// Copyright (c) 2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


module wf8ldpcenc_dpu (
    // System signals
    input clk,                  // system clock
    input rst_n,                // system asynchronous reset, active low

    // Data interface
    input [1:0] state,          // current state
    input [3:0] mode,           // input encoder mode, [1:0]:rate, [3:2]:codeword length
    input ldpc2x,               // LDPC2x mode indication
    input [5:0] cnt_sym,        // counter of symbol
    input [1:0] cnt_vld,        // counter of valid
    input [1:0] cnt_vld_max,    // maximum value of counter of valid
    input clr_acc,              // clear accumulator
    input vld,                  // valid input
    input [26:0] data_r,        // registered data
    output reg [26:0] data_out  // output data
);

// Local parameters
localparam ST_IDLE = 2'd0;
localparam ST_MSG  = 2'd1;
localparam ST_WAIT = 2'd2;
localparam ST_PRT  = 2'd3;


// Local signals
wire [9:0] addr;
reg [80:0] msg;
wire z54;
reg en_acc;
reg [3:0] sel_xi;
reg [1:0] sel_p0;
reg sel_pi;
wire en_pi;
reg [4:0] cnt_sym_mid;
wire [9:0] sh1, sh2, sh3, sh4, sh5, sh6, sh7, sh8, sh9, sh10, sh11, sh12;
wire [80:0] rcs1, rcs2, rcs3, rcs4, rcs5, rcs6, rcs7, rcs8, rcs9, rcs10, rcs11, rcs12;
reg [80:0] x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12;
reg [80:0] xx1, xx2, xx3, xx4, xx5, xx6, xx7, xx8, xx9, xx10, xx11, xx12;
wire [80:0] p0, pp0;
wire [80:0] p0_rsh1, pp0_rsh1;
reg [80:0] xi, xxi;
wire [80:0] p0_mux, pi_mux;
wire [80:0] pp0_mux, ppi_mux;
reg [80:0] pi, ppi;
wire [80:0] prt, pprt;


// Control signals
assign addr = {mode, cnt_sym};

always @(posedge clk) begin
    if (state == ST_MSG && vld == 1'b1) begin
        if (cnt_vld == 2'd0)
            msg <= {data_r, data_r, data_r};
        else if (cnt_vld == 2'd1)
            msg <= {msg[80:54], data_r, msg[26:0]};
        else
            msg <= {data_r, msg[53:0]};
    end
end

assign z54 = (mode[3:2] == 2'd1) ? 1'b1 : 1'b0;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        en_acc <= 1'b0;
    else if (state == ST_MSG && vld == 1'b1 && cnt_vld == cnt_vld_max)
        en_acc <= 1'b1;
    else
        en_acc <= 1'b0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        sel_xi <= 4'd0;
    else if (state == ST_PRT) begin
        if (cnt_vld == cnt_vld_max)
            sel_xi <= (~ldpc2x) ? cnt_sym[3:0] : (cnt_sym[0]) ? cnt_sym[4:1] : sel_xi;
    end
    else
        sel_xi <= 4'd15;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        sel_p0 <= 2'd0;
    else if (state == ST_WAIT)
        sel_p0 <= 2'd1;
    else if (state == ST_PRT) begin
        if (cnt_vld == cnt_vld_max) begin
            if (~ldpc2x) begin
                if (cnt_sym[4:0] == 5'd0)
                    sel_p0 <= 2'd2;
                else if (cnt_sym[4:0] == cnt_sym_mid)
                    sel_p0 <= 2'd1;
                else
                    sel_p0 <= 2'd0;
            end
            else if (cnt_sym[0]) begin
                if (cnt_sym[5:1] == 5'd0)
                    sel_p0 <= 2'd2;
                else if (cnt_sym[5:1] == cnt_sym_mid)
                    sel_p0 <= 2'd1;
                else
                    sel_p0 <= 2'd0;
            end
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        sel_pi <= 1'b0;
    else if (state == ST_PRT) begin
        if (cnt_vld == cnt_vld_max) begin
            if (ldpc2x == 1'b0 && cnt_sym[4:0] != 5'd0)
                sel_pi <= 1'b1;
            else if (ldpc2x == 1'b1 && cnt_sym[0] == 1'b1 && cnt_sym[5:1] != 5'd0)
                sel_pi <= 1'b1;
        end
    end
    else
        sel_pi <= 1'b0;
end

assign en_pi = (state == ST_PRT && cnt_vld == cnt_vld_max && ((~ldpc2x) | cnt_sym[0])) ? 1'b1 : 1'b0;

always @(*) begin
    case (mode[1:0])
        2'd0: cnt_sym_mid = 5'd6;
        2'd1: cnt_sym_mid = 5'd4;
        2'd2: cnt_sym_mid = 5'd3;
        default: cnt_sym_mid = 5'd2;
    endcase
end


// Processing unit
wf8ldpcenc_tbl u_wf8ldpcenc_tbl (
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

wf8ldpcenc_rcs u1_wf8ldpcenc_rcs (
    .d_in           (msg),
    .sh             (sh1[7:0]),
    .d_out          (rcs1)
);

wf8ldpcenc_rcs u2_wf8ldpcenc_rcs (
    .d_in           (msg),
    .sh             (sh2[7:0]),
    .d_out          (rcs2)
);

wf8ldpcenc_rcs u3_wf8ldpcenc_rcs (
    .d_in           (msg),
    .sh             (sh3[7:0]),
    .d_out          (rcs3)
);

wf8ldpcenc_rcs u4_wf8ldpcenc_rcs (
    .d_in           (msg),
    .sh             (sh4[7:0]),
    .d_out          (rcs4)
);

wf8ldpcenc_rcs u5_wf8ldpcenc_rcs (
    .d_in           (msg),
    .sh             (sh5[7:0]),
    .d_out          (rcs5)
);

wf8ldpcenc_rcs u6_wf8ldpcenc_rcs (
    .d_in           (msg),
    .sh             (sh6[7:0]),
    .d_out          (rcs6)
);

wf8ldpcenc_rcs u7_wf8ldpcenc_rcs (
    .d_in           (msg),
    .sh             (sh7[7:0]),
    .d_out          (rcs7)
);

wf8ldpcenc_rcs u8_wf8ldpcenc_rcs (
    .d_in           (msg),
    .sh             (sh8[7:0]),
    .d_out          (rcs8)
);

wf8ldpcenc_rcs u9_wf8ldpcenc_rcs (
    .d_in           (msg),
    .sh             (sh9[7:0]),
    .d_out          (rcs9)
);

wf8ldpcenc_rcs u10_wf8ldpcenc_rcs (
    .d_in           (msg),
    .sh             (sh10[7:0]),
    .d_out          (rcs10)
);

wf8ldpcenc_rcs u11_wf8ldpcenc_rcs (
    .d_in           (msg),
    .sh             (sh11[7:0]),
    .d_out          (rcs11)
);

wf8ldpcenc_rcs u12_wf8ldpcenc_rcs (
    .d_in           (msg),
    .sh             (sh12[7:0]),
    .d_out          (rcs12)
);

always @(posedge clk) begin
    if (clr_acc) begin
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
        xx1 <= 81'd0;
        xx2 <= 81'd0;
        xx3 <= 81'd0;
        xx4 <= 81'd0;
        xx5 <= 81'd0;
        xx6 <= 81'd0;
        xx7 <= 81'd0;
        xx8 <= 81'd0;
        xx9 <= 81'd0;
        xx10 <= 81'd0;
        xx11 <= 81'd0;
        xx12 <= 81'd0;
    end
    else if (en_acc) begin
        if (sh1[9:8] == 2'b01)    x1 <= x1 ^ rcs1;
        if (sh2[9:8] == 2'b01)    x2 <= x2 ^ rcs2;
        if (sh3[9:8] == 2'b01)    x3 <= x3 ^ rcs3;
        if (sh4[9:8] == 2'b01)    x4 <= x4 ^ rcs4;
        if (sh5[9:8] == 2'b01)    x5 <= x5 ^ rcs5;
        if (sh6[9:8] == 2'b01)    x6 <= x6 ^ rcs6;
        if (sh7[9:8] == 2'b01)    x7 <= x7 ^ rcs7;
        if (sh8[9:8] == 2'b01)    x8 <= x8 ^ rcs8;
        if (sh9[9:8] == 2'b01)    x9 <= x9 ^ rcs9;
        if (sh10[9:8] == 2'b01)    x10 <= x10 ^ rcs10;
        if (sh11[9:8] == 2'b01)    x11 <= x11 ^ rcs11;
        if (sh12[9:8] == 2'b01)    x12 <= x12 ^ rcs12;
        if (sh1[9:8] == 2'b11)    xx1 <= xx1 ^ rcs1;
        if (sh2[9:8] == 2'b11)    xx2 <= xx2 ^ rcs2;
        if (sh3[9:8] == 2'b11)    xx3 <= xx3 ^ rcs3;
        if (sh4[9:8] == 2'b11)    xx4 <= xx4 ^ rcs4;
        if (sh5[9:8] == 2'b11)    xx5 <= xx5 ^ rcs5;
        if (sh6[9:8] == 2'b11)    xx6 <= xx6 ^ rcs6;
        if (sh7[9:8] == 2'b11)    xx7 <= xx7 ^ rcs7;
        if (sh8[9:8] == 2'b11)    xx8 <= xx8 ^ rcs8;
        if (sh9[9:8] == 2'b11)    xx9 <= xx9 ^ rcs9;
        if (sh10[9:8] == 2'b11)    xx10 <= xx10 ^ rcs10;
        if (sh11[9:8] == 2'b11)    xx11 <= xx11 ^ rcs11;
        if (sh12[9:8] == 2'b11)    xx12 <= xx12 ^ rcs12;
    end
end

assign p0 = x1 ^ x2 ^ x3 ^ x4 ^ x5 ^ x6 ^ x7 ^ x8 ^ x9 ^ x10 ^ x11 ^ x12;
assign pp0 = xx1 ^ xx2 ^ xx3 ^ xx4 ^ xx5 ^ xx6 ^ xx7 ^ xx8 ^ xx9 ^ xx10 ^ xx11 ^ xx12;

always @(*) begin
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

always @(*) begin
    case (sel_xi)
        4'd0 : xxi = xx1;
        4'd1 : xxi = xx2;
        4'd2 : xxi = xx3;
        4'd3 : xxi = xx4;
        4'd4 : xxi = xx5;
        4'd5 : xxi = xx6;
        4'd6 : xxi = xx7;
        4'd7 : xxi = xx8;
        4'd8 : xxi = xx9;
        4'd9 : xxi = xx10;
        4'd10: xxi = xx11;
        4'd11: xxi = xx12;
        default: xxi = 81'd0;
    endcase
end

assign p0_rsh1 = {p0[0], p0[80:55], ((z54) ? p0[0] : p0[54]), p0[53:1]};
assign p0_mux = (sel_p0 == 2'd0) ? 81'd0 : (sel_p0 == 2'd1) ? p0 : p0_rsh1;
assign pi_mux = (sel_pi) ? pi : 81'd0;
assign prt = p0_mux ^ pi_mux ^ xi;

assign pp0_rsh1 = {pp0[0], pp0[80:55], ((z54) ? pp0[0] : pp0[54]), pp0[53:1]};
assign pp0_mux = (sel_p0 == 2'd0) ? 81'd0 : (sel_p0 == 2'd1) ? pp0 : pp0_rsh1;
assign ppi_mux = (sel_pi) ? ppi : 81'd0;
assign pprt = pp0_mux ^ ppi_mux ^ xxi;

always @(posedge clk) begin
    if (en_pi)
        pi <= prt;
end

always @(posedge clk) begin
    if (en_pi)
        ppi <= pprt;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        data_out <= 27'd0;
     else if (state == ST_MSG)
        data_out <= data_r;
    else if (state == ST_PRT) begin
        if (ldpc2x & cnt_sym[0]) begin
            if (cnt_vld == 2'd0)
                data_out <= pprt[26:0];
            else if (cnt_vld == 2'd1)
                data_out <= pprt[53:27];
            else
                data_out <= pprt[80:54];
        end
        else begin
            if (cnt_vld == 2'd0)
                data_out <= prt[26:0];
            else if (cnt_vld == 2'd1)
                data_out <= prt[53:27];
            else
                data_out <= prt[80:54];
        end
    end
end


endmodule
