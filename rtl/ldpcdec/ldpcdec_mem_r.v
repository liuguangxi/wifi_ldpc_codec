//==============================================================================
// ldpcdec_mem_r.v
//
// Memory for check node LLR (Lr) storage.
// Simple dual port synchronous SRAM, data depth = 128, data width = `W_CHK*81.
//------------------------------------------------------------------------------
// Copyright (c) 2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


`include "ldpcdec_cfg.vh"


module ldpcdec_mem_r (
    // System signals
    input clk,                          // read/write clock

    // Data interface
    input we,                           // write enable
    input [6:0] waddr,                  // write address
    input [`W_CHK*81-1:0] din,          // write data input
    input re,                           // read enable
    input [6:0] raddr,                  // read address
    output [`W_CHK*81-1:0] dout         // read data output
);

`ifdef FPGA_XLNX
xlnx_ram_sdp #(
    .RAM_STYLE      ("distributed"),
    .DP             (128),
    .DW             (`W_CHK*81)
) u_ram_sdp (
    .clk            (clk),
    .we             (we),
    .waddr          (waddr),
    .din            (din),
    .re             (re),
    .raddr          (raddr),
    .dout           (dout)
);
`endif


endmodule
