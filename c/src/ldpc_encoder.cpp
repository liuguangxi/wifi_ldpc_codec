//==============================================================================
// ldpc_encoder.cpp
//
// LDPC encoder implementation.
//------------------------------------------------------------------------------
// Copyright (c) 2019-2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


#include "ldpc_encoder.h"
#include <cstdlib>
#include <iostream>
#include <algorithm>

using namespace std;


//----------------------------------------------------------
// Right rotate vector
//
// Inout:
//     vec: vector to be rotated
//
// Input:
//     sh: right rotate shift number, negative number for zeros vector output
//----------------------------------------------------------
static void rotateVector(vector<int>& vec, int sh)
{
    if (sh < 0)
        fill(vec.begin(), vec.end(), 0);
    else
        rotate(vec.begin(), vec.begin() + sh, vec.end());
}


//----------------------------------------------------------
// LDPC encoder core
//
// Input:
//     dataIn: message data bits, value is 0 or 1
//     h: base parity check matrix
//
// Return:
//     codeword data bits, value is 0 or 1
//----------------------------------------------------------
vector<int> ldpcEncodeCore(const vector<int>& dataIn, const PcmBase& pcm)
{
    int kb = pcm.nb - pcm.rb;
    if (dataIn.size() != static_cast<vector<int>::size_type>(kb * pcm.z)) {
        cerr << "Error: Invalid input data size" << dataIn.size()
             << ", should be " << kb * pcm.z << endl;
        exit(EXIT_FAILURE);
    }

    vector<int> x(pcm.rb * pcm.z);
    vector<int> p(pcm.rb * pcm.z);
    vector<int> t;

    for (int i = 0; i < pcm.rb; i++) {
        for (int j = 0; j < kb; j++) {
            t.assign(dataIn.begin() + j * pcm.z, dataIn.begin() + (j + 1) * pcm.z);
            rotateVector(t, pcm.base[i * pcm.nb + j]);
            for (int ii = 0; ii < pcm.z; ii++)
                x[i * pcm.z + ii] = (x[i * pcm.z + ii] + t[ii]) % 2;
        }
    }

    for (int i = 0; i < pcm.rb; i++) {
        for (int ii = 0; ii < pcm.z; ii++)
            p[ii] = (p[ii] + x[i * pcm.z + ii]) % 2;
    }

    t.assign(p.begin(), p.begin() + pcm.z);
    rotateVector(t, 1);
    for (int i = 1; i < pcm.rb; i++) {
        for (int ii = 0; ii < pcm.z; ii++) {
            if (i == 1)
                p[i * pcm.z + ii] = (x[(i - 1) * pcm.z + ii] + t[ii]) % 2;
            else if (i == pcm.rb / 2 + 1)
                p[i * pcm.z + ii] = (x[(i - 1) * pcm.z + ii] + p[ii] + p[(i - 1) * pcm.z + ii]) % 2;
            else
                p[i * pcm.z + ii] = (x[(i - 1) * pcm.z + ii] + p[(i - 1) * pcm.z + ii]) % 2;
        }
    }

    vector<int> cw(dataIn);
    cw.insert(cw.end(), p.begin(), p.end());
    return cw;
}


//----------------------------------------------------------
// LDPC encoder core for codeword block length 3888 bits
//
// Input:
//     dataIn: message data bits, value is 0 or 1
//     h: base parity check matrix
//
// Return:
//     codeword data bits, value is 0 or 1
//----------------------------------------------------------
vector<int> ldpc2xEncodeCore(const vector<int>& dataIn, const PcmBase& pcm)
{
    int kb = pcm.nb - pcm.rb;
    if (dataIn.size() != static_cast<vector<int>::size_type>(kb * pcm.z)) {
        cerr << "Error: Invalid input data size" << dataIn.size()
             << ", should be " << kb * pcm.z << endl;
        exit(EXIT_FAILURE);
    }

    vector<int> x(pcm.rb * pcm.z);
    vector<int> p(pcm.rb * pcm.z);
    vector<int> t, tt;

    for (int i = 0; i < pcm.rb; i++) {
        for (int j = 0; j < kb; j++) {
            t.assign(dataIn.begin() + j * pcm.z, dataIn.begin() + (j + 1) * pcm.z);
            rotateVector(t, pcm.base[i * pcm.nb + j]);
            for (int ii = 0; ii < pcm.z; ii++)
                x[i * pcm.z + ii] = (x[i * pcm.z + ii] + t[ii]) % 2;
        }
    }

    for (int i = 0; i < pcm.rb; i += 2) {
        for (int ii = 0; ii < pcm.z; ii++) {
            p[ii] = (p[ii] + x[i * pcm.z + ii]) % 2;
            p[pcm.z + ii] = (p[pcm.z + ii] + x[(i + 1) * pcm.z + ii]) % 2;
        }
    }

    t.assign(p.begin(), p.begin() + pcm.z);
    rotateVector(t, 1);
    tt.assign(p.begin() + pcm.z, p.begin() + 2 * pcm.z);
    rotateVector(tt, 1);
    for (int i = 2; i < pcm.rb; i++) {
        for (int ii = 0; ii < pcm.z; ii++) {
            if (i == 2)
                p[i * pcm.z + ii] = (x[(i - 2) * pcm.z + ii] + t[ii]) % 2;
            else if (i == 3)
                p[i * pcm.z + ii] = (x[(i - 2) * pcm.z + ii] + tt[ii]) % 2;
            else if (i == pcm.rb / 2 + 2)
                p[i * pcm.z + ii] = (x[(i - 2) * pcm.z + ii] + p[ii] + p[(i - 2) * pcm.z + ii]) % 2;
            else if (i == pcm.rb / 2 + 3)
                p[i * pcm.z + ii] = (x[(i - 2) * pcm.z + ii] + p[pcm.z + ii] + p[(i - 2) * pcm.z + ii]) % 2;
            else
                p[i * pcm.z + ii] = (x[(i - 2) * pcm.z + ii] + p[(i - 2) * pcm.z + ii]) % 2;
        }
    }

    vector<int> cw(dataIn);
    cw.insert(cw.end(), p.begin(), p.end());
    return cw;
}


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
vector<int> ldpcEncode(const vector<int>& dataIn, CodeMode mode)
{
    int idxHldpc = static_cast<int>(mode);
    if (idxHldpc < 12)
        return ldpcEncodeCore(dataIn, Hldpc[idxHldpc]);
    else    // codeword block length 3888 bits
        return ldpc2xEncodeCore(dataIn, Hldpc[idxHldpc]);
}
