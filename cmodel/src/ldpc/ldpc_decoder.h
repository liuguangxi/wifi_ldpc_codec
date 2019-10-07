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
// LDPC decoder with sum-product algorithm
//
// Input:
//     dataIn: demapped LLR data
//     mode: mode of codeword length and code rate
//     maxIter: maximum number of decoding iterations
//
// Return:
//     decoded message data bits, value is 0 or 1
//----------------------------------------------------------
std::vector<int> ldpcDecodeSP(const std::vector<double>& dataIn,
                              CodeMode mode, int maxIter);


#endif // LDPC_DECODER_H
