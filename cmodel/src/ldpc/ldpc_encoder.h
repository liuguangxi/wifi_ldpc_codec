//==============================================================================
// ldpc_encoder.h
//
// LDPC encoder header.
//------------------------------------------------------------------------------
// Copyright (c) 2019 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


#ifndef LDPC_ENCODER_H
#define LDPC_ENCODER_H


#include "ldpc/ldpc_matrix.h"
#include <vector>


//----------------------------------------------------------
// LDPC encoder
//
// Input:
//     dataIn: message data bits, value is 0 or 1
//     mode: mode of codeword length and code rate
//
// Return:
//     codeword data bits, value is 0 or 1
//----------------------------------------------------------
std::vector<int> ldpcEncode(const std::vector<int>& dataIn, CodeMode mode);


#endif // LDPC_ENCODER_H
