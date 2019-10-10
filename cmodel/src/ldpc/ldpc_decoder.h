//==============================================================================
// ldpc_decoder.h
//
// LDPC decoder header.
//------------------------------------------------------------------------------
// Copyright (c) 2019 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


#ifndef LDPC_DECODER_H
#define LDPC_DECODER_H


#include "ldpc/ldpc_matrix.h"
#include <vector>


//----------------------------------------------------------
// Get parity check matrix graph
//
// Input:
//     idxHldpc: index of Hldpc
//
// Return:
//     Parity check matrix graph for Hldpc with index idxHldpc
//----------------------------------------------------------
PcmGraph getPcmGraph(int idxHldpc);


//----------------------------------------------------------
// LDPC decoder core with sum-product algorithm
//
// Input:
//     dataIn: demapped LLR data
//     pg: parity check matrix graph
//     maxIter: maximum number of decoding iterations
//     earlyExit: whether decoding terminates after all parity checks are satisfied
//
// Output:
//     numIter: actual number of iterations performed
//
// Return:
//     decoded message data bits, value is 0 or 1
//----------------------------------------------------------
std::vector<int> ldpcDecodeSPCore(const std::vector<double>& dataIn,
                                  const PcmGraph& pg, int maxIter, bool earlyExit,
                                  int &numIter);


//----------------------------------------------------------
// LDPC decoder with sum-product algorithm
//
// Input:
//     dataIn: demapped LLR data
//     mode: mode of codeword length and code rate
//     maxIter: maximum number of decoding iterations
//     earlyExit: whether decoding terminates after all parity checks are satisfied
//
// Output:
//     numIter: actual number of iterations performed
//
// Return:
//     decoded message data bits, value is 0 or 1
//----------------------------------------------------------
std::vector<int> ldpcDecodeSP(const std::vector<double>& dataIn,
                              CodeMode mode, int maxIter, bool earlyExit,
                              int &numIter);


#endif // LDPC_DECODER_H
