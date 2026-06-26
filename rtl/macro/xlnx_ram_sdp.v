//==============================================================================
// xlnx_ram_sdp.v
//
// Generic simple dual port synchronous SRAM for Xilinx FPGA.
// Single clock.
//------------------------------------------------------------------------------
// Copyright (c) 2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


module xlnx_ram_sdp #(
    parameter RAM_STYLE = "auto",   // RAM style attribute
    parameter DP = 32,              // RAM data depth
    parameter DW = 8                // RAM data width
)
(
    input clk,                      // read/write clock
    input we,                       // write enable
    input [$clog2(DP)-1:0] waddr,   // write address
    input [DW-1:0] din,             // write data input
    input re,                       // read enable
    input [$clog2(DP)-1:0] raddr,   // read address
    output reg [DW-1:0] dout        // read data output
);

// Local signals
(* ram_style = RAM_STYLE *) reg [DW-1:0] mem [DP-1:0];


// Read/Write logic
always @(posedge clk) begin
    if (we)
        mem[waddr] <= din;
end

always @(posedge clk) begin
    if (re)
        dout <= mem[raddr];
end


endmodule
