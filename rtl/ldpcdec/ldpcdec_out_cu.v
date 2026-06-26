//==============================================================================
// ldpcdec_out_cu.v
//
// Output controller unit of Wi-Fi LDPC decoder.
//------------------------------------------------------------------------------
// Copyright (c) 2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


module ldpcdec_out_cu (
    // System signals
    input clk,                      // system clock
    input rst_n,                    // system asynchronous reset, active low
    input srst,                     // synchronous reset

    // Data interface
    input start,                    // start outputting data
    input [3:0] mode_in,            // input decoder mode, [1:0]:rate, [3:2]:codeword length
    input [5:0] num_iter_in,        // input actual number of iterations
    input pc_in,                    // input parity check result
    output reg rdy_dec,             // ready to start decoding
    output reg vld_out,             // output data valid
    output reg sop_out,             // output start of packet
    output reg eop_out,             // output end of packet
    output reg [5:0] num_iter,      // output actual number of iterations
    output reg pc,                  // output parity check result
    output reg [26:0] data_out,     // output data

    // Memory interface
    input we_lq_hd,                 // memory write enable for LQ hard decision bits
    input [4:0] waddr_lq_hd,        // memory write address for LQ hard decision bits
    input [80:0] din_lq_hd,         // memory write input LQ hard decision bits
    output ce_mem_out,              // chip enable for out memory
    output we_mem_out,              // write enable for out memory
    output [4:0] addr_mem_out,      // read/write address for out memory
    output [80:0] din_mem_out,      // data input for out memory
    input [80:0] dout_mem_out       // data output for out memory
);

// Local parameters
localparam ST_IDLE = 1'b0;
localparam ST_OUT  = 1'b1;


// Local signals
reg cs, ns;
reg [4:0] msg_sym_len;
reg [4:0] cnt_sym_max;
reg [1:0] cnt_vld_max;
reg [4:0] cnt_sym;
reg [4:0] cnt_sym_r;
reg [1:0] cnt_vld;
reg [1:0] cnt_vld_r;
wire re_lq_hd;
wire [4:0] raddr_lq_hd;


// FSM
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cs <= ST_IDLE;
    else if (srst)
        cs <= ST_IDLE;
    else
        cs <= ns;
end

always @(*) begin
    ns = cs;
    case (cs)
        ST_IDLE: if (start)    ns = ST_OUT;
        ST_OUT: if (cnt_sym_r == msg_sym_len && cnt_vld_r == cnt_vld_max)    ns = ST_IDLE;
        default: ns = ST_IDLE;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        msg_sym_len <= 5'd0;
    else if (cs == ST_IDLE && start == 1'b1) begin
        case (mode_in[1:0])
            2'd0: msg_sym_len <= 5'd11;
            2'd1: msg_sym_len <= 5'd15;
            2'd2: msg_sym_len <= 5'd17;
            default: msg_sym_len <= 5'd19;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt_sym_max <= 5'd0;
    else if (cs == ST_IDLE && start == 1'b1) begin
        case (mode_in)
            4'b00_00: cnt_sym_max <= 5'd3;
            4'b00_01: cnt_sym_max <= 5'd7;
            4'b00_10: cnt_sym_max <= 5'd9;
            4'b00_11: cnt_sym_max <= 5'd11;
            4'b01_00: cnt_sym_max <= 5'd7;
            4'b01_01: cnt_sym_max <= 5'd11;
            4'b01_10: cnt_sym_max <= 5'd13;
            4'b01_11: cnt_sym_max <= 5'd15;
            4'b10_00: cnt_sym_max <= 5'd9;
            4'b10_01: cnt_sym_max <= 5'd13;
            4'b10_10: cnt_sym_max <= 5'd15;
            4'b10_11: cnt_sym_max <= 5'd17;
            default: cnt_sym_max <= 5'd0;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt_vld_max <= 2'd0;
    else if (cs == ST_IDLE && start == 1'b1)
        cnt_vld_max <= mode_in[3:2];
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt_sym <= 5'd0;
    else if (start) begin
        if (cnt_vld == mode_in[3:2])
            cnt_sym <= cnt_sym + 1'b1;
    end
    else if (cs == ST_OUT) begin
        if (cnt_vld == cnt_vld_max)
            cnt_sym <= cnt_sym + 1'b1;
    end
    else
        cnt_sym <= 5'd0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt_vld <= 2'd0;
    else if (start) begin
        cnt_vld <= (cnt_vld == mode_in[3:2]) ? 2'd0 : (cnt_vld + 1'b1);
    end
    else if (cs == ST_OUT) begin
        cnt_vld <= (cnt_vld == cnt_vld_max) ? 2'd0 : (cnt_vld + 1'b1);
    end
    else
        cnt_vld <= 2'd0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt_sym_r <= 5'd0;
        cnt_vld_r <= 2'd0;
    end
    else begin
        cnt_sym_r <= cnt_sym;
        cnt_vld_r <= cnt_vld;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        rdy_dec <= 1'b1;
    else if (start)
        rdy_dec <= 1'b0;
    else if (cs == ST_OUT) begin
        if (cnt_sym_r == cnt_sym_max)
            rdy_dec <= 1'b1;
    end
    else
        rdy_dec <= 1'b1;
end


// Memory controller
assign re_lq_hd = (start == 1'b1 || cs == ST_OUT) ? 1'b1 : 1'b0;
assign raddr_lq_hd = cnt_sym;

assign ce_mem_out = we_lq_hd | re_lq_hd;
assign we_mem_out = we_lq_hd;
assign addr_mem_out = (we_lq_hd) ? waddr_lq_hd : raddr_lq_hd;
assign din_mem_out = din_lq_hd;


// Output signals
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        num_iter <= 6'd0;
    else if (start)
        num_iter <= num_iter_in;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        pc <= 1'b0;
    else if (start)
        pc <= pc_in;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        sop_out <= 1'b0;
    else if (cs == ST_OUT && cnt_sym_r == 5'd0 && cnt_vld_r == 2'd0)
        sop_out <= 1'b1;
    else
        sop_out <= 1'b0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        eop_out <= 1'b0;
    else if (cs == ST_OUT && cnt_sym_r == msg_sym_len && cnt_vld_r == cnt_vld_max)
        eop_out <= 1'b1;
    else
        eop_out <= 1'b0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        vld_out <= 1'b0;
    else if (cs == ST_OUT)
        vld_out <= 1'b1;
    else
        vld_out <= 1'b0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        data_out <= 27'd0;
     else if (cs == ST_OUT) begin
        if (cnt_vld_r == 2'd0)
            data_out <= dout_mem_out[26:0];
        else if (cnt_vld_r == 2'd1)
            data_out <= dout_mem_out[53:27];
        else
            data_out <= dout_mem_out[80:54];
    end
end


endmodule
