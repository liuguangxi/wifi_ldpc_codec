//==============================================================================
// ldpc_decoder_fx.h
//
// LDPC decoder (fixed-point) header.
//------------------------------------------------------------------------------
// Copyright (c) 2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


#ifndef LDPC_DECODER_FX_H
#define LDPC_DECODER_FX_H


#include "ldpc_matrix.h"
#include <vector>


// Fixed-point parameters configuration
struct FxConfig {
    int F_IN;    // bit width of fractional part of input LLR
    int W_IN;    // bit width of LLR input
    int W_CHK;    // bit width of check node LLR
    int W_VAR;    // bit width of variable node LLR
};


//----------------------------------------------------------
// LDPC decoder core with layered normalized minimum-sum algorithm (fixed-point)
//
// Input:
//     dataIn: demapped LLR data
//     pcm: parity check matrix
//     maxIter: maximum number of decoding iterations
//     scInt: quantized scaling factor
//     earlyExit: whether decoding terminates after all parity checks are satisfied
//     cfgFx: configuration object for fixed-point
//
// Output:
//     numIter: actual number of iterations performed
//
// Return:
//     decoded message data bits, value is 0 or 1
//----------------------------------------------------------
std::vector<int> ldpcDecodeLNMSFxCore(const std::vector<int>& dataIn,
                                      const PcmBase& pcm, int maxIter,
                                      int scInt, bool earlyExit,
                                      const FxConfig& cfgFx,
                                      int& numIter);


//----------------------------------------------------------
// LDPC decoder with layered normalized minimum-sum algorithm (fixed-point)
//
// Input:
//     dataIn: demapped LLR data
//     mode: mode of codeword length and code rate
//     maxIter: maximum number of decoding iterations
//     sc: scaling factor
//     earlyExit: whether decoding terminates after all parity checks are satisfied
//     cfgFx: configuration object for fixed-point
//
// Output:
//     numIter: actual number of iterations performed
//
// Return:
//     decoded message data bits, value is 0 or 1
//----------------------------------------------------------
std::vector<int> ldpcDecodeLNMSFx(const std::vector<double>& dataIn,
                                  CodeMode mode, int maxIter,
                                  double sc, bool earlyExit,
                                  const FxConfig& cfgFx,
                                  int& numIter);


//----------------------------------------------------------
// LDPC decoder core with layered offset minimum-sum algorithm (fixed-point)
//
// Input:
//     dataIn: demapped LLR data
//     pcm: parity check matrix
//     maxIter: maximum number of decoding iterations
//     osInt: quantized offset
//     earlyExit: whether decoding terminates after all parity checks are satisfied
//
// Output:
//     numIter: actual number of iterations performed
//
// Return:
//     decoded message data bits, value is 0 or 1
//----------------------------------------------------------
std::vector<int> ldpcDecodeLOMSFxCore(const std::vector<int>& dataIn,
                                      const PcmBase& pcm, int maxIter,
                                      int osInt, bool earlyExit,
                                      const FxConfig& cfgFx,
                                      int& numIter);


//----------------------------------------------------------
// LDPC decoder with layered offset minimum-sum algorithm (fixed-point)
//
// Input:
//     dataIn: demapped LLR data
//     mode: mode of codeword length and code rate
//     maxIter: maximum number of decoding iterations
//     os: offset
//     earlyExit: whether decoding terminates after all parity checks are satisfied
//
// Output:
//     numIter: actual number of iterations performed
//
// Return:
//     decoded message data bits, value is 0 or 1
//----------------------------------------------------------
std::vector<int> ldpcDecodeLOMSFx(const std::vector<double>& dataIn,
                                  CodeMode mode, int maxIter,
                                  double os, bool earlyExit,
                                  const FxConfig& cfgFx,
                                  int& numIter);


#endif // LDPC_DECODER_FX_H
