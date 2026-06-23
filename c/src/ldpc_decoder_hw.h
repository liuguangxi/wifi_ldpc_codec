//==============================================================================
// ldpc_decoder_hw.h
//
// LDPC decoder (hardware model) header.
//------------------------------------------------------------------------------
// Copyright (c) 2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


#ifndef LDPC_DECODER_HW_H
#define LDPC_DECODER_HW_H


#include "ldpc_matrix.h"
#include <vector>


// Row permutation
struct RowPerm {
    int p[12];    // permutation vector
};

extern const RowPerm RPldpc[12];


// Hardware parameters configuration
struct HwConfig {
    int F_IN;    // bit width of fractional part of input LLR
    int W_IN;    // bit width of LLR input
    int W_CHK;    // bit width of check node LLR
    int W_VAR;    // bit width of variable node LLR
    int MS_ALG;    // min-sum algorithm (0:MS, 1:NMS, 2:OMS)
    bool HAS_PC;    // whether including parity check
};


//----------------------------------------------------------
// Row permutate base parity check matrix
//
// Input:
//     pcm: parity check matrix
//     rp: row permutation
//
// Return:
//     parity check matrix after row permutation
//----------------------------------------------------------
PcmBase rowPermutePcmBase(const PcmBase& pcm, const RowPerm& rp);


//----------------------------------------------------------
// LDPC decoder core hardware model
//
// Input:
//     dataIn: demapped LLR data
//     pcm: parity check matrix
//     maxIter: maximum number of decoding iterations
//     scSel: scaling factor for NMS (0:0.75, 1:0.8125)
//     earlyExit: whether decoding terminates after all parity checks are satisfied
//     cfgHw: configuration object for hardware
//
// Output:
//     numIter: actual number of iterations performed
//     pc: parity check status indicator
//
// Return:
//     decoded message data bits, value is 0 or 1
//----------------------------------------------------------
std::vector<int> ldpcDecodeHwCore(const std::vector<int>& dataIn,
                                  const PcmBase& pcm, int maxIter,
                                  int scSel, bool earlyExit,
                                  const HwConfig& cfgHw,
                                  int& numIter, bool& pc);


//----------------------------------------------------------
// LDPC decoder hardware model
//
// Input:
//     dataIn: demapped LLR data
//     mode: mode of codeword length and code rate
//     maxIter: maximum number of decoding iterations
//     scSel: scaling factor for NMS (0:0.75, 1:0.8125)
//     earlyExit: whether decoding terminates after all parity checks are satisfied
//     cfgHw: configuration object for hardware
//
// Output:
//     numIter: actual number of iterations performed
//     pc: parity check status indicator
//
// Return:
//     decoded message data bits, value is 0 or 1
//----------------------------------------------------------
std::vector<int> ldpcDecodeHw(const std::vector<double>& dataIn,
                              CodeMode mode, int maxIter,
                              int scSel, bool earlyExit,
                              const HwConfig& cfgHw,
                              int& numIter, bool& pc);


#endif // LDPC_DECODER_HW_H
