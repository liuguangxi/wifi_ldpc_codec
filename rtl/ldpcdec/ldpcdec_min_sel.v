//==============================================================================
// ldpcdec_min_sel.v
//
// Select minimum and second minimum Lq.
//------------------------------------------------------------------------------
// Copyright (c) 2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


`include "ldpcdec_cfg.vh"


module ldpcdec_min_sel (
    // System signals
    input clk,                          // system clock

    // Data interface
    input sc_sel,                       // scaling factor for normalized min-sum
    input clr,                          // clear internal variables
    input vld,                          // input valid for Lq
    input eol,                          // end of layer for Lq
    input [4:0] idx_in,                 // input index of Lq
    input [`W_VAR-1:0] lq_sm_in,        // input Lq in sign-magnitude format
    output reg sgn_out,                 // output Lq product sign
    output reg [4:0] min_idx_out,       // output index of minimum Lq for current layer
    output reg [`W_VAR-2:0] min_out,    // output minimum Lq for current layer
    output reg [`W_VAR-2:0] min2_out    // output second minimum Lq for current layer
);

// Local parameters
localparam integer ALG = `MS_ALG;
localparam [`W_VAR-2:0] OS_INT = (1'b1 << (`F_IN-1));
localparam [`W_VAR-2:0] M_MAX = {(`W_VAR-1){1'b1}};


// Local signals
wire le_min;
wire le_min2;
wire sgn_nxt;
reg sgn_r;
wire [4:0] min_idx_nxt;
reg [4:0] min_idx_r;
wire [`W_VAR-2:0] min_nxt;
reg [`W_VAR-2:0] min_r;
wire [`W_VAR-2:0] min2_nxt;
reg [`W_VAR-2:0] min2_r;
wire [`W_VAR+2:0] lq_mag_sc;
wire [`W_VAR-1:0] lq_mag_os;
wire [`W_VAR-2:0] lq_mag_ms;
wire [`W_VAR-2:0] min_ms_nxt;
reg [`W_VAR-2:0] min_ms_r;
wire [`W_VAR-2:0] min2_ms_nxt;
reg [`W_VAR-2:0] min2_ms_r;


// Update sign, minimum and second minimum
assign sgn_nxt = sgn_r ^ lq_sm_in[`W_VAR-1];

assign le_min = (lq_sm_in[`W_VAR-2:0] <= min_r) ? 1'b1 : 1'b0;
assign le_min2 = (lq_sm_in[`W_VAR-2:0] <= min2_r) ? 1'b1 : 1'b0;
assign min_idx_nxt = (le_min) ? idx_in : min_idx_r;
assign min_nxt = (le_min) ? lq_sm_in[`W_VAR-2:0] : min_r;
assign min2_nxt = (le_min) ? min_r : (le_min2) ? lq_sm_in[`W_VAR-2:0] : min2_r;

always @(posedge clk) begin
    if (clr | eol) begin
        sgn_r <= 1'b0;
        min_r <= M_MAX;
        min2_r <= M_MAX;
    end
    else if (vld) begin
        sgn_r <= sgn_nxt;
        min_r <= min_nxt;
        min2_r <= min2_nxt;
    end
end

always @(posedge clk) begin
    if (vld)
        min_idx_r <= min_idx_nxt;
end


// Min-sum algorithm
generate
    if (ALG == 1) begin : g_nms
        // Normalized min-sum
        assign lq_mag_sc = {1'b0, lq_sm_in[`W_VAR-2:0], 3'd0} + {2'd0, lq_sm_in[`W_VAR-2:0], 2'd0}
                         + {4'd0, lq_sm_in[`W_VAR-2:0] & {(`W_VAR-1){sc_sel}}}
                         + {{(`W_VAR-1){1'b0}}, 4'b1000};
        assign lq_mag_ms = lq_mag_sc[`W_VAR+2:4];
    end

    if (ALG == 2) begin : g_oms
        // Offset min-sum
        assign lq_mag_os = lq_sm_in[`W_VAR-2:0] - OS_INT;
        assign lq_mag_ms = (lq_mag_os[`W_VAR-1]) ? {(`W_VAR-1){1'b0}} : lq_mag_os[`W_VAR-2:0];
    end

    if (ALG >= 1) begin : g_nms_oms
        assign min_ms_nxt = (le_min) ? lq_mag_ms : min_ms_r;
        assign min2_ms_nxt = (le_min) ? min_ms_r : (le_min2) ? lq_mag_ms : min2_ms_r;

        always @(posedge clk) begin
            if (vld) begin
                min_ms_r <= min_ms_nxt;
                min2_ms_r <= min2_ms_nxt;
            end
        end
    end
endgenerate


// Output result of current layer
always @(posedge clk) begin
    if (eol) begin
        min_idx_out <= min_idx_nxt;
        sgn_out <= sgn_nxt;
    end
end

generate
    if (ALG == 0) begin : g_ms_out
        always @(posedge clk) begin
            if (eol) begin
                min_out <= min_nxt;
                min2_out <= min2_nxt;
            end
        end
    end
    else begin : g_nms_oms_out
        always @(posedge clk) begin
            if (eol) begin
                min_out <= min_ms_nxt;
                min2_out <= min2_ms_nxt;
            end
        end
    end
endgenerate


endmodule
