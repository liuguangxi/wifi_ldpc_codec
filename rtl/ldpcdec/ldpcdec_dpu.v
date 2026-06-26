//==============================================================================
// ldpcdec_dpu.v
//
// Datapath unit of Wi-Fi LDPC decoder.
//------------------------------------------------------------------------------
// Copyright (c) 2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


`include "ldpcdec_cfg.vh"


module ldpcdec_dpu (
    // System signals
    input clk,                          // system clock
    input rst_n,                        // system asynchronous reset, active low

    // Data interface
    input [3:0] mode,                   // decoder mode, [1:0]:rate, [3:2]:codeword length
    input [5:0] max_iter_r,             // maximum iteration, 1 - 63
    input sc_sel_r,                     // scaling factor for normalized min-sum
    input early_term_r,                 // early terminate decoding
    input init,                         // initialize variables
    input en_dec,                       // enable decoding
    input chk,                          // check decoding result
    input [4:0] cnt_sym,                // counter of symbol
    input [1:0] cnt_vld,                // counter of valid
    input [1:0] cnt_vld_max,            // maximum value of counter of valid
    input [6:0] cnt_dec,                // counter of decoding
    input cnt_dec_flg,                  // counter of decoding flag
    input vld,                          // data valid
    input [`W_VAR*27-1:0] data_r,       // sign extended data
    output reg done_dec,                // finish decoding
    output reg start_out,               // start outputting data
    output reg [3:0] mode_out,          // output decoder mode, [1:0]:rate, [3:2]:codeword length
    output reg [5:0] num_iter_out,      // output actual number of iterations
    output reg pc_out,                  // output parity check result

    // Memory interface
    output we_mem_q,                    // write enable for LQ memory
    output [4:0] waddr_mem_q,           // write address for LQ memory
    output [`W_VAR*81-1:0] din_mem_q,   // write data input for LQ memory
    output re_mem_q,                    // read enable for LQ memory
    output [4:0] raddr_mem_q,           // read address for LQ memory
    input [`W_VAR*81-1:0] dout_mem_q,   // read data output for LQ memory
    output we_mem_t,                    // write enable for Lq memory
    output [4:0] waddr_mem_t,           // write address for Lq memory
    output [`W_VAR*81-1:0] din_mem_t,   // write data input for Lq memory
    output re_mem_t,                    // read enable for Lq memory
    output [4:0] raddr_mem_t,           // read address for Lq memory
    input [`W_VAR*81-1:0] dout_mem_t,   // read data output for Lq memory
    output we_mem_r,                    // write enable for Lr memory
    output [6:0] waddr_mem_r,           // write address for Lr memory
    output [`W_CHK*81-1:0] din_mem_r,   // write data input for Lr memory
    output re_mem_r,                    // read enable for Lr memory
    output [6:0] raddr_mem_r,           // read address for Lr memory
    input [`W_CHK*81-1:0] dout_mem_r,   // read data output for Lr memory
    output we_lq_hd,                    // memory write enable for LQ hard decision bits
    output [4:0] waddr_lq_hd,           // memory write address for LQ hard decision bits
    output [80:0] din_lq_hd             // memory write input LQ hard decision bits
);

// Local signals
wire [11:0] addr;
wire [4:0] q_raddr;
wire q_byp;
wire [8:0] q_sh;
wire [1:0] q_vld;
wire [6:0] r_raddr;
wire r_vld;
wire [4:0] t_raddr;
wire t_byp;
wire t_vld;
wire [6:0] r_waddr;
wire [8:0] q_hd_sh;
wire [4:0] q_hd_waddr;
wire q_hd_vld;
reg we_llr_in;
reg [4:0] waddr_llr_in;
reg [`W_VAR*81-1:0] din_llr_in;
reg q_byp_r1;
wire [`W_VAR*81-1:0] rdata_mem_q;
reg [1:0] q_vld_r1;
reg [8:0] q_sh_r1;
wire [`W_VAR*81-1:0] lq_rcs;
reg r_vld_r1;
reg [6:0] r_raddr_r1;
reg [1:0] q_vld_r2;
reg r_vld_r2;
wire [`W_VAR*81-1:0] lq_tc;
wire [`W_VAR*81-1:0] lq_sm;
reg [1:0] q_vld_r3;
reg [4:0] q_raddr_r1;
reg [4:0] q_raddr_r2;
reg [4:0] q_raddr_r3;
wire [80:0] sgn;
wire [404:0] min_idx;
wire [(`W_VAR-1)*81-1:0] min;
wire [(`W_VAR-1)*81-1:0] min2;
reg t_byp_r1;
reg [`W_VAR*81-1:0] lq_tc_r;
wire [`W_VAR*81-1:0] rdata_mem_t;
reg t_vld_r1;
reg [4:0] t_raddr_r1;
wire [`W_VAR*81-1:0] lq_out;
wire [`W_CHK*81-1:0] lr_out;
reg [`W_VAR*81-1:0] lq_out_r;
reg t_vld_r2;
reg [4:0] t_raddr_r2;
wire [80:0] lq_hd;
genvar i;
reg chk_r;
wire pc_res;
reg [5:0] num_iter;
wire [80:0] lq_hd_rcs;
reg [80:0] lq_hd_rcs_r;
reg [4:0] q_hd_waddr_r1;
reg q_hd_vld_r1;


// Main lookup tables
assign addr = {mode, cnt_dec_flg, cnt_dec};

ldpcdec_main_tbl u_ldpcdec_main_tbl (
    .clk            (clk),
    .rst_n          (rst_n),
    .addr           (addr),
    .q_raddr        (q_raddr),
    .q_byp          (q_byp),
    .q_sh           (q_sh),
    .q_vld          (q_vld),
    .r_raddr        (r_raddr),
    .r_vld          (r_vld),
    .t_raddr        (t_raddr),
    .t_byp          (t_byp),
    .t_vld          (t_vld),
    .r_waddr        (r_waddr),
    .q_hd_sh        (q_hd_sh),
    .q_hd_waddr     (q_hd_waddr),
    .q_hd_vld       (q_hd_vld)
);


// input LLR controller
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        we_llr_in <= 1'b0;
    else
        we_llr_in <= (vld == 1'b1) && (cnt_vld == cnt_vld_max);
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        waddr_llr_in <= 5'h0;
    else
        waddr_llr_in <= cnt_sym;
end

always @(posedge clk) begin
    if (vld) begin
        if (cnt_vld == 2'd0)
            din_llr_in <= {data_r, data_r, data_r};
        else if (cnt_vld == 2'd1)
            din_llr_in <= {din_llr_in[`W_VAR*81-1:`W_VAR*54], data_r, din_llr_in[`W_VAR*27-1:0]};
        else
            din_llr_in <= {data_r, din_llr_in[`W_VAR*54-1:0]};
    end
end


// LQ memory read controller
assign re_mem_q = q_vld[0] & en_dec;
assign raddr_mem_q = q_raddr;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        q_byp_r1 <= 1'b0;
    else
        q_byp_r1 <= q_byp & en_dec;
end

assign rdata_mem_q = (q_byp_r1) ? lq_out_r : dout_mem_q;


// Variable node LLR RCS controller
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        q_vld_r1 <= 2'h0;
    else
        q_vld_r1 <= q_vld & {2{en_dec}};
end

always @(posedge clk) begin
    q_sh_r1 <= q_sh;
end

ldpcdec_vn_rcs_vec u_ldpcdec_vn_rcs_vec (
    .clk            (clk),
    .vld            (q_vld_r1[0]),
    .d_in           (rdata_mem_q),
    .sh             (q_sh_r1),
    .d_out          (lq_rcs)
);


// Lr memory read controller
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        r_vld_r1 <= 1'b0;
    else
        r_vld_r1 <= r_vld & en_dec;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        r_raddr_r1 <= 7'h0;
    else
        r_raddr_r1 <= r_raddr;
end

assign re_mem_r = r_vld_r1;
assign raddr_mem_r = r_raddr_r1;


// Calculate Lq
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        q_vld_r2 <= 2'h0;
    else
        q_vld_r2 <= q_vld_r1;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        r_vld_r2 <= 1'b0;
    else
        r_vld_r2 <= r_vld_r1;
end

ldpcdec_calc_lq_vec u_ldpcdec_calc_lq_vec (
    .clk            (clk),
    .vld_lq         (q_vld_r2[0]),
    .lq_in          (lq_rcs),
    .vld_lr         (r_vld_r2),
    .lr_in          (dout_mem_r),
    .lq_tc_out      (lq_tc),
    .lq_sm_out      (lq_sm)
);


// Select minimum and second minimum Lq
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        q_vld_r3 <= 2'h0;
    else
        q_vld_r3 <= q_vld_r2;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        q_raddr_r1 <= 5'h0;
        q_raddr_r2 <= 5'h0;
        q_raddr_r3 <= 5'h0;
    end
    else begin
        q_raddr_r1 <= q_raddr;
        q_raddr_r2 <= q_raddr_r1;
        q_raddr_r3 <= q_raddr_r2;
    end
end

ldpcdec_min_sel_vec u_ldpcdec_min_sel_vec (
    .clk            (clk),
    .sc_sel         (sc_sel_r),
    .clr            (init),
    .vld            (q_vld_r3[0]),
    .eol            (q_vld_r3[1]),
    .idx_in         (q_raddr_r3),
    .lq_sm_in       (lq_sm),
    .sgn_out        (sgn),
    .min_idx_out    (min_idx),
    .min_out        (min),
    .min2_out       (min2)
);


// Lq memory controller
assign we_mem_t = q_vld_r3[0];
assign waddr_mem_t = q_raddr_r3;
assign din_mem_t = lq_tc;
assign re_mem_t = t_vld;
assign raddr_mem_t = t_raddr;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        t_byp_r1 <= 1'b0;
    else
        t_byp_r1 <= t_byp;
end

always @(posedge clk) begin
    lq_tc_r <= lq_tc;
end

assign rdata_mem_t = (t_byp_r1) ? lq_tc_r : dout_mem_t;


// Calculate updated LQ and Lr
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        t_vld_r1 <= 1'b0;
    else
        t_vld_r1 <= t_vld;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        t_raddr_r1 <= 5'h0;
    else
        t_raddr_r1 <= t_raddr;
end

ldpcdec_calc_vn_cn_vec u_ldpcdec_calc_vn_cn_vec (
    .clk            (clk),
    .sgn            (sgn),
    .min_idx        (min_idx),
    .min            (min),
    .min2           (min2),
    .vld            (t_vld_r1),
    .idx_in         (t_raddr_r1),
    .lq_in          (rdata_mem_t),
    .lq_out         (lq_out),
    .lr_out         (lr_out)
);

always @(posedge clk) begin
    lq_out_r <= lq_out;
end


// LQ memory write controller
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        t_vld_r2 <= 1'b0;
    else
        t_vld_r2 <= t_vld_r1;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        t_raddr_r2 <= 5'h0;
    else
        t_raddr_r2 <= t_raddr_r1;
end

assign we_mem_q = t_vld_r2 | we_llr_in;
assign waddr_mem_q = (en_dec) ? t_raddr_r2 : waddr_llr_in;
assign din_mem_q = (en_dec) ? lq_out : din_llr_in;


// Lr memory write controller
assign we_mem_r = t_vld_r2;
assign waddr_mem_r = r_waddr;
assign din_mem_r = lr_out;


// Process LQ hard decision bits
generate
    for (i = 0; i < 81; i = i + 1) begin : g_lq_hd
        assign lq_hd[i] = lq_out[i*`W_VAR+`W_VAR-1];
    end
endgenerate


// Calculate parity check result
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        chk_r <= 1'b0;
    else
        chk_r <= chk;
end

`ifdef HAS_PC
ldpcdec_calc_pc u_ldpcdec_calc_pc (
    .clk            (clk),
    .clr            (init | chk_r),
    .addr           (addr),
    .lq_hd_in       (lq_hd),
    .pc_out         (pc_res)
);
`else
assign pc_res = 1'b0;
`endif


// Iteration termination controller
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        num_iter <= 6'd0;
    else if (en_dec) begin
        if (chk)
            num_iter <= num_iter + 1'b1;
    end
    else
        num_iter <= 6'd0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        done_dec <= 1'b0;
        start_out <= 1'b0;
        mode_out <= 4'd0;
        num_iter_out <= 6'd0;
        pc_out <= 1'b0;
    end
    else if (chk_r) begin
        if ((early_term_r & pc_res) || (num_iter == max_iter_r)) begin
            done_dec <= 1'b1;
            start_out <= 1'b1;
            mode_out <= mode;
            num_iter_out <= num_iter;
            pc_out <= pc_res;
        end
    end
    else begin
        done_dec <= 1'b0;
        start_out <= 1'b0;
    end
end


// Out memory write controller
ldpcdec_rcs u_ldpcdec_rcs (
    .d_in           (lq_hd),
    .sh             (q_hd_sh),
    .d_out          (lq_hd_rcs)
);

always @(posedge clk) begin
    if (q_hd_vld)
        lq_hd_rcs_r <= lq_hd_rcs;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        q_hd_waddr_r1 <= 5'h0;
    else
        q_hd_waddr_r1 <= q_hd_waddr;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        q_hd_vld_r1 <= 1'b0;
    else
        q_hd_vld_r1 <= q_hd_vld;
end

assign we_lq_hd = q_hd_vld_r1;
assign waddr_lq_hd = q_hd_waddr_r1;
assign din_lq_hd = lq_hd_rcs_r;


endmodule
