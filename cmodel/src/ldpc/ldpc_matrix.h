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


enum CodeMode {
    C648R12, C648R23, C648R34, C648R56,
    C1296R12, C1296R23, C1296R34, C1296R56,
    C1944R12, C1944R23, C1944R34, C1944R56
};


struct MatrixType {
    int m;    // number of rows
    int n;    // number of columns
    int z;    // expand factor
    int base[288];    // base matrix
};


extern const MatrixType Hldpc[12];


#endif // LDPC_MATRIX_H
