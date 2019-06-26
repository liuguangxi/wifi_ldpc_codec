//==============================================================================
// ldpcenc_cu.v
//
// Controller unit of Wi-Fi LDPC encoder.
//------------------------------------------------------------------------------
// Copyright (c) 2019 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


module ldpcenc_cu (
    // System signals
    input clk,                      // system clock
    input rst_n,                    // system asynchronous reset, active low
    input srst,                     // synchronous reset

    // Data interface
    input vld_in,                   // input data valid
    input sop_in,                   // input start of packet
    input [3:0] mode_in,            // input encoder mode, [1:0]:rate, [3:2]:codeword length
    input [26:0] data_in,           // input data
    output rdy_in,                  // ready to receive input data
    output reg vld_out,             // output data valid
    output reg sop_out,             // output start of packet
    output [1:0] state,             // current state
    output reg [3:0] mode,          // input encoder mode, [1:0]:rate, [3:2]:codeword length
    output reg [4:0] cnt_sym,       // counter of symbol
    output reg [1:0] cnt_vld,       // counter of valid
    output reg [1:0] cnt_vld_max,   // maximum value of counter of valid
    output clr_acc,                 // clear accumulator
    output reg vld,                 // data valid
    output reg [26:0] data_r1,      // registered data 1
    output reg [26:0] data_r2,      // registered data 2
    output reg [26:0] data_r3       // registered data 3
);

// Local parameters
localparam ST_IDLE = 2'd0;
localparam ST_MSG  = 2'd1;
localparam ST_WAIT = 2'd2;
localparam ST_PRT  = 2'd3;


// Local signals
reg [1:0] cs, ns;
reg sop;
reg [4:0] msg_sym_len;
reg [4:0] prt_sym_len;


// FSM
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        cs <= ST_IDLE;
    else if (srst)
        cs <= ST_IDLE;
    else
        cs <= ns;
end

always @ (*) begin
    ns = cs;
    case (cs)
        ST_IDLE: if (sop_in)    ns = ST_MSG;
        ST_MSG: if (cnt_sym == msg_sym_len && cnt_vld == cnt_vld_max)    ns = ST_WAIT;
        ST_WAIT: ns = ST_PRT;
        ST_PRT: if (cnt_sym == prt_sym_len && cnt_vld == cnt_vld_max)    ns = ST_IDLE;
        default: ns = ST_IDLE;
    endcase
end

assign state = cs;

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        sop <= 1'b0;
    else if (cs == ST_IDLE && sop_in == 1'b1)
        sop <= 1'b1;
    else
        sop <= 1'b0;
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        vld <= 1'b0;
    else
        vld <= vld_in;
end

assign clr_acc = sop;

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        mode <= 4'd0;
    else if (cs == ST_IDLE && sop_in == 1'b1)
        mode <= mode_in;
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        msg_sym_len <= 5'd0;
    else if (cs == ST_IDLE && sop_in == 1'b1) begin
        case (mode_in[1:0])
            2'd0: msg_sym_len <= 5'd11;
            2'd1: msg_sym_len <= 5'd15;
            2'd2: msg_sym_len <= 5'd17;
            2'd3: msg_sym_len <= 5'd19;
            default: msg_sym_len <= 5'd11;
        endcase
    end
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        prt_sym_len <= 5'd0;
    else if (cs == ST_IDLE && sop_in == 1'b1) begin
        case (mode_in[1:0])
            2'd0: prt_sym_len <= 5'd11;
            2'd1: prt_sym_len <= 5'd7;
            2'd2: prt_sym_len <= 5'd5;
            2'd3: prt_sym_len <= 5'd3;
            default: prt_sym_len <= 5'd11;
        endcase
    end
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt_vld_max <= 2'd0;
    else if (cs == ST_IDLE && sop_in == 1'b1)
        cnt_vld_max <= mode_in[3:2];
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt_sym <= 5'd0;
    else if (cs == ST_MSG) begin
        if (vld_in == 1'b1 && cnt_vld == cnt_vld_max)
            cnt_sym <= cnt_sym + 1'b1;
    end
    else if (cs == ST_PRT) begin
        if (cnt_vld == cnt_vld_max)
            cnt_sym <= cnt_sym + 1'b1;
    end
    else
        cnt_sym <= 5'd0;
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt_vld <= 2'd0;
    else if (cs == ST_MSG) begin
        if (vld_in)
            cnt_vld <= (cnt_vld == cnt_vld_max) ? 2'd0 : (cnt_vld + 1'b1);
    end
    else if (cs == ST_PRT) begin
        cnt_vld <= (cnt_vld == cnt_vld_max) ? 2'd0 : (cnt_vld + 1'b1);
    end
    else
        cnt_vld <= 2'd0;
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_r1 <= 27'd0;
        data_r2 <= 27'd0;
        data_r3 <= 27'd0;
    end
    else if ((cs == ST_IDLE && sop_in == 1'b1) || (cs == ST_MSG && vld_in == 1'b1)) begin
        data_r1 <= data_in;
        data_r2 <= data_r1;
        data_r3 <= data_r2;
    end
end


// Output data
assign rdy_in = (cs == ST_IDLE || cs == ST_MSG) ? 1'b1 : 1'b0;

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        sop_out <= 1'b0;
    else if (cs == ST_MSG)
        sop_out <= sop;
    else
        sop_out <= 1'b0;
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        vld_out <= 1'b0;
    else if (cs == ST_MSG)
        vld_out <= vld;
    else if (cs == ST_PRT)
        vld_out <= 1'b1;
    else
        vld_out <= 1'b0;
end


endmodule
