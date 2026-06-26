//==============================================================================
// xlnx_ram_sp.v
//
// Generic single port synchronous SRAM for Xilinx FPGA.
// Write mode is NO_CHANGE.
//------------------------------------------------------------------------------
// Copyright (c) 2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


module xlnx_ram_sp #(
    parameter RAM_STYLE = "auto",   // RAM style attribute
    parameter DP = 32,              // RAM data depth
    parameter DW = 8                // RAM data width
)
(
    input clk,                      // read/write clock
    input ce,                       // chip enable
    input we,                       // write enable
    input [$clog2(DP)-1:0] addr,    // read/write address
    input [DW-1:0] din,             // data input
    output reg [DW-1:0] dout        // data output
);

// Local signals
(* ram_style = RAM_STYLE *) reg [DW-1:0] mem [DP-1:0];


// Read/Write logic
always @(posedge clk) begin
    if (ce) begin
        if (we)
            mem[addr] <= din;
        else
            dout <= mem[addr];
    end
end


endmodule
