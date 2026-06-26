//==============================================================================
// ldpcdec_mem_out.v
//
// Memory for hard decision bits output storage.
// Single port synchronous SRAM, data depth = 32, data width = 81.
//------------------------------------------------------------------------------
// Copyright (c) 2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


module ldpcdec_mem_out (
    // System signals
    input clk,                      // read/write clock

    // Data interface
    input ce,                       // chip enable
    input we,                       // write enable
    input [4:0] addr,               // read/write address
    input [80:0] din,               // data input
    output [80:0] dout              // data output
);

`ifdef FPGA_XLNX
xlnx_ram_sp #(
    .RAM_STYLE      ("distributed"),
    .DP             (32),
    .DW             (81)
) u_ram_sp (
    .clk            (clk),
    .ce             (ce),
    .we             (we),
    .addr           (addr),
    .din            (din),
    .dout           (dout)
);
`endif


endmodule
