//==============================================================================
// syn_harness.v
//
// Synthesis harness input and output logic.
//------------------------------------------------------------------------------
// Copyright (c) 2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


(* dont_touch = "true" *)
module syn_harness_in #(
    parameter integer WIDTH = 1  // word length of output (>= 1)
)
(
    input clk,
    input bit_in,
    output [WIDTH-1:0] word_out
);

// Shift registers
generate
    reg [WIDTH-1:0] bit_in_r;

    if (WIDTH <= 1) begin : g_width_1
        always @(posedge clk) begin
            bit_in_r <= bit_in;
        end
    end else begin : g_width_gt1
        always @(posedge clk) begin
            bit_in_r <= {bit_in_r[WIDTH-2:0], bit_in};
        end
    end

    assign word_out = bit_in_r;
endgenerate


endmodule


(* dont_touch = "true" *)
module syn_harness_out #(
    parameter integer WIDTH = 1  // word length of input (>= 1)
)
(
    input clk,
    input [WIDTH-1:0] word_in,
    output bit_out
);

// Register and reduce
reg [WIDTH-1:0] word_in_r;
reg bit_out_r;

always @(posedge clk) begin
    word_in_r <= word_in;
    bit_out_r = ^word_in_r;
end

assign bit_out = bit_out_r;


endmodule
