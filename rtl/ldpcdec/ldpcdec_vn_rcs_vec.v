//==============================================================================
// ldpcdec_vn_rcs_vec.v
//
// Variable node LLR RCS (vector unit).
//------------------------------------------------------------------------------
// Copyright (c) 2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


`include "ldpcdec_cfg.vh"


module ldpcdec_vn_rcs_vec (
    // System signals
    input clk,                          // system clock

    // Data interface
    input vld,                          // input valid
    input [`W_VAR*81-1:0] d_in,         // input data
    input [8:0] sh,                     // [6:0]:right shift number, [8:7]:output mux
    output reg [`W_VAR*81-1:0] d_out    // output data
);

// Local signals
wire [80:0] rcs_in [`W_VAR-1:0];
wire [80:0] rcs_out [`W_VAR-1:0];
wire [`W_VAR*81-1:0] vec_out;
genvar i, j;


// Processing
generate
    for (i = 0; i < `W_VAR; i = i + 1) begin : g_rcs
        // Get input vector
        for (j = 0; j < 81; j = j + 1) begin : g_rcs_in
            assign rcs_in[i][j] = d_in[j * `W_VAR + i];
        end

        // Instance of RCS
        ldpcdec_rcs u_ldpcdec_rcs (
            .d_in           (rcs_in[i]),
            .sh             (sh),
            .d_out          (rcs_out[i])
        );

        // Get output vector
        for (j = 0; j < 81; j = j + 1) begin : g_rcs_out
            assign vec_out[j * `W_VAR + i] = rcs_out[i][j];
        end
    end
endgenerate

always @(posedge clk) begin
    if (vld)
        d_out <= vec_out;
end


endmodule
