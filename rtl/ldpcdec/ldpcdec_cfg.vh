//==============================================================================
// ldpcdec_cfg.vh
//
// Configuration constants for Wi-Fi LDPC decoder.
//------------------------------------------------------------------------------
// Copyright (c) 2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


// The bit width of LLRs
// F_IN: bit width of fractional part of input LLR
// W_IN: bit width of LLR input
// W_CHK: bit width of check node LLR
// W_VAR: bit width of variable node LLR
// Numerical constraint: 0 <= F_IN < W_IN <= W_CHK < W_VAR
`define F_IN  2
`define W_IN  6
`define W_CHK  6
`define W_VAR  8


// The min-sum algorithm type
// 0: min-sum, no corrections
// 1: normalized min-sum (alpha = 0.75 or 0.8125)
// 2: offset min-sum (beta = 0.5)
`define MS_ALG  1


// If defined, include parity check logic
`define HAS_PC


// If defined, use generic RAM model for Xilinx FPGA
`define FPGA_XLNX
