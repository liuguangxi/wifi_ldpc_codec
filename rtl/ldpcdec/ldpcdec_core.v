//==============================================================================
// ldpcdec_core.v
//
// Top module of Wi-Fi LDPC decoder.
//------------------------------------------------------------------------------
// Copyright (c) 2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


`include "ldpcdec_cfg.vh"


module ldpcdec_core (
    // System signals
    input clk,                      // system clock
    input rst_n,                    // system asynchronous reset, active low
    input srst,                     // synchronous reset

    // Data interface
    input vld_in,                   // input data valid
    input sop_in,                   // input start of packet
    input [3:0] mode_in,            // decoder mode, [1:0]:rate, [3:2]:codeword length
    input [5:0] max_iter,           // maximum iteration, 1 - 63
    input sc_sel,                   // scaling factor for normalized min-sum
    input early_term,               // early terminate decoding
    input [`W_IN*27-1:0] data_in,   // input LLR data
    output rdy_in,                  // ready to receive input data
    output vld_out,                 // output data valid
    output sop_out,                 // output start of packet
    output eop_out,                 // output end of packet
    output [5:0] num_iter,          // output actual number of iterations
    output pc,                      // output parity check result
    output [26:0] data_out          // output data
);

// Local signals
wire rdy_dec;
wire done_dec;
wire [3:0] mode;
wire [5:0] max_iter_r;
wire sc_sel_r;
wire early_term_r;
wire init;
wire en_dec;
wire chk;
wire [4:0] cnt_sym;
wire [1:0] cnt_vld;
wire [1:0] cnt_vld_max;
wire [6:0] cnt_dec;
wire cnt_dec_flg;
wire vld;
wire [`W_VAR*27-1:0] data_r;
wire start_out;
wire [3:0] mode_out;
wire [5:0] num_iter_out;
wire pc_out;
wire we_mem_q;
wire [4:0] waddr_mem_q;
wire [`W_VAR*81-1:0] din_mem_q;
wire re_mem_q;
wire [4:0] raddr_mem_q;
wire [`W_VAR*81-1:0] dout_mem_q;
wire we_mem_t;
wire [4:0] waddr_mem_t;
wire [`W_VAR*81-1:0] din_mem_t;
wire re_mem_t;
wire [4:0] raddr_mem_t;
wire [`W_VAR*81-1:0] dout_mem_t;
wire we_mem_r;
wire [6:0] waddr_mem_r;
wire [`W_CHK*81-1:0] din_mem_r;
wire re_mem_r;
wire [6:0] raddr_mem_r;
wire [`W_CHK*81-1:0] dout_mem_r;
wire we_lq_hd;
wire [4:0] waddr_lq_hd;
wire [80:0] din_lq_hd;
wire ce_mem_out;
wire we_mem_out;
wire [4:0] addr_mem_out;
wire [80:0] din_mem_out;
wire [80:0] dout_mem_out;


// Instances of logic module
ldpcdec_main_cu u_ldpcdec_main_cu (
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
    .rdy_dec        (rdy_dec),
    .done_dec       (done_dec),
    .mode           (mode),
    .max_iter_r     (max_iter_r),
    .sc_sel_r       (sc_sel_r),
    .early_term_r   (early_term_r),
    .init           (init),
    .en_dec         (en_dec),
    .chk            (chk),
    .cnt_sym        (cnt_sym),
    .cnt_vld        (cnt_vld),
    .cnt_vld_max    (cnt_vld_max),
    .cnt_dec        (cnt_dec),
    .cnt_dec_flg    (cnt_dec_flg),
    .vld            (vld),
    .data_r         (data_r)
);

ldpcdec_dpu u_ldpcdec_dpu (
    .clk            (clk),
    .rst_n          (rst_n),
    .mode           (mode),
    .max_iter_r     (max_iter_r),
    .sc_sel_r       (sc_sel_r),
    .early_term_r   (early_term_r),
    .init           (init),
    .en_dec         (en_dec),
    .chk            (chk),
    .cnt_sym        (cnt_sym),
    .cnt_vld        (cnt_vld),
    .cnt_vld_max    (cnt_vld_max),
    .cnt_dec        (cnt_dec),
    .cnt_dec_flg    (cnt_dec_flg),
    .vld            (vld),
    .data_r         (data_r),
    .done_dec       (done_dec),
    .start_out      (start_out),
    .mode_out       (mode_out),
    .num_iter_out   (num_iter_out),
    .pc_out         (pc_out),
    .we_mem_q       (we_mem_q),
    .waddr_mem_q    (waddr_mem_q),
    .din_mem_q      (din_mem_q),
    .re_mem_q       (re_mem_q),
    .raddr_mem_q    (raddr_mem_q),
    .dout_mem_q     (dout_mem_q),
    .we_mem_t       (we_mem_t),
    .waddr_mem_t    (waddr_mem_t),
    .din_mem_t      (din_mem_t),
    .re_mem_t       (re_mem_t),
    .raddr_mem_t    (raddr_mem_t),
    .dout_mem_t     (dout_mem_t),
    .we_mem_r       (we_mem_r),
    .waddr_mem_r    (waddr_mem_r),
    .din_mem_r      (din_mem_r),
    .re_mem_r       (re_mem_r),
    .raddr_mem_r    (raddr_mem_r),
    .dout_mem_r     (dout_mem_r),
    .we_lq_hd       (we_lq_hd),
    .waddr_lq_hd    (waddr_lq_hd),
    .din_lq_hd      (din_lq_hd)
);

ldpcdec_out_cu u_ldpcdec_out_cu (
    .clk            (clk),
    .rst_n          (rst_n),
    .srst           (srst),
    .start          (start_out),
    .mode_in        (mode_out),
    .num_iter_in    (num_iter_out),
    .pc_in          (pc_out),
    .rdy_dec        (rdy_dec),
    .vld_out        (vld_out),
    .sop_out        (sop_out),
    .eop_out        (eop_out),
    .num_iter       (num_iter),
    .pc             (pc),
    .data_out       (data_out),
    .we_lq_hd       (we_lq_hd),
    .waddr_lq_hd    (waddr_lq_hd),
    .din_lq_hd      (din_lq_hd),
    .ce_mem_out     (ce_mem_out),
    .we_mem_out     (we_mem_out),
    .addr_mem_out   (addr_mem_out),
    .din_mem_out    (din_mem_out),
    .dout_mem_out   (dout_mem_out)
);


// Instances of memories
ldpcdec_mem_q u_ldpcdec_mem_q (
    .clk            (clk),
    .we             (we_mem_q),
    .waddr          (waddr_mem_q),
    .din            (din_mem_q),
    .re             (re_mem_q),
    .raddr          (raddr_mem_q),
    .dout           (dout_mem_q)
);

ldpcdec_mem_t u_ldpcdec_mem_t (
    .clk            (clk),
    .we             (we_mem_t),
    .waddr          (waddr_mem_t),
    .din            (din_mem_t),
    .re             (re_mem_t),
    .raddr          (raddr_mem_t),
    .dout           (dout_mem_t)
);

ldpcdec_mem_r u_ldpcdec_mem_r (
    .clk            (clk),
    .we             (we_mem_r),
    .waddr          (waddr_mem_r),
    .din            (din_mem_r),
    .re             (re_mem_r),
    .raddr          (raddr_mem_r),
    .dout           (dout_mem_r)
);

ldpcdec_mem_out u_ldpcdec_mem_out (
    .clk            (clk),
    .ce             (ce_mem_out),
    .we             (we_mem_out),
    .addr           (addr_mem_out),
    .din            (din_mem_out),
    .dout           (dout_mem_out)
);


endmodule
