//==============================================================================
// ldpcenc_rcs.v
//
// Right cyclic shifter of 81 bits.
//------------------------------------------------------------------------------
// Copyright (c) 2019-2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


module ldpcenc_rcs (
    // Data interface
    input [80:0] d_in,          // input data
    input [7:0] sh,             // [6:0]:right shift number, [7]:output mux
    output [80:0] d_out         // output data
);

// Local signals
wire [80:0] d0, d1, d2, d3, d4, d5, d6;
wire [26:0] mux_d6;


// Barrel shifter and multiplexer
assign d0 = (sh[0]) ? {d_in[0], d_in[80:1]} : d_in;
assign d1 = (sh[1]) ? {d0[1:0], d0[80:2]} : d0;
assign d2 = (sh[2]) ? {d1[3:0], d1[80:4]} : d1;
assign d3 = (sh[3]) ? {d2[7:0], d2[80:8]} : d2;
assign d4 = (sh[4]) ? {d3[15:0], d3[80:16]} : d3;
assign d5 = (sh[5]) ? {d4[31:0], d4[80:32]} : d4;
assign d6 = (sh[6]) ? {d5[63:0], d5[80:64]} : d5;

assign mux_d6 = (sh[7]) ? d6[80:54] : d6[53:27];
assign d_out = {d6[80:54], mux_d6, d6[26:0]};


endmodule
