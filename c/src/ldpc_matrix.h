//==============================================================================
// ldpc_matrix.h
//
// LDPC matrix type definitions and values header.
//------------------------------------------------------------------------------
// Copyright (c) 2019 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


#ifndef LDPC_MATRIX_H
#define LDPC_MATRIX_H


#include <vector>


enum CodeMode {
    N648CR12,       // n = 648,  cr = 1/2
    N648CR23,       // n = 648,  cr = 2/3
    N648CR34,       // n = 648,  cr = 3/4
    N648CR56,       // n = 648,  cr = 5/6
    N1296CR12,      // n = 1296, cr = 1/2
    N1296CR23,      // n = 1296, cr = 2/3
    N1296CR34,      // n = 1296, cr = 3/4
    N1296CR56,      // n = 1296, cr = 5/6
    N1944CR12,      // n = 1944, cr = 1/2
    N1944CR23,      // n = 1944, cr = 2/3
    N1944CR34,      // n = 1944, cr = 3/4
    N1944CR56       // n = 1944, cr = 5/6
};

struct PcmBase {
    int z;    // expand factor
    int rb;    // number of rows
    int nb;    // number of columns
    int base[288];    // base matrix
};

struct PcmGraph {
    int r;    // number of rows
    int n;    // number of columns
    std::vector<int> rows;    // row position of non-zero element of parity check matrix
    std::vector<int> cols;    // column position of non-zero element of parity check matrix
};


extern const PcmBase Hldpc[12];


#endif // LDPC_MATRIX_H
