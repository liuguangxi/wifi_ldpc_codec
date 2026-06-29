//==============================================================================
// ldpc_decoder_hw.cpp
//
// LDPC decoder (hardware model) implementation.
//------------------------------------------------------------------------------
// Copyright (c) 2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


#include "ldpc_decoder_hw.h"
#include <cstdlib>
#include <cmath>
#include <iostream>
#include <utility>
#include <algorithm>

using namespace std;


// Row permutation for each mode
const RowPerm RPldpc[12] = {
    {1, 9, 2, 6, 11, 10, 7, 5, 12, 3, 8, 4},    // N648CR12
    {1, 2, 3, 4, 5, 6, 7, 8},    // N648CR23
    {1, 6, 2, 3, 5, 4},    // N648CR34
    {1, 3, 2, 4},    // N648CR56
    {1, 7, 3, 12, 11, 6, 2, 8, 4, 10, 5, 9},    // N1296CR12
    {1, 6, 3, 4, 5, 8, 7, 2},    // N1296CR23
    {1, 2, 3, 4, 5, 6},    // N1296CR34
    {1, 3, 2, 4},    // N1296CR56
    {1, 12, 7, 9, 5, 8, 4, 6, 2, 11, 3, 10},    // N1944CR12
    {1, 7, 3, 4, 5, 6, 2, 8},    // N1944CR23
    {1, 4, 2, 3, 5, 6},    // N1944CR34
    {1, 3, 2, 4}    // N1944CR56
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
PcmBase rowPermutePcmBase(const PcmBase& pcm, const RowPerm& rp)
{
    PcmBase pcmOut = pcm;
    for (int i = 0; i < pcm.rb; i++) {
        int pi = rp.p[i] - 1;
        for (int j = 0; j < pcm.nb; j++) {
            pcmOut.base[i * pcm.nb + j] = pcm.base[pi * pcm.nb + j];
        }
    }
    return pcmOut;
}


//----------------------------------------------------------
// Quantize input LLR data
//
// Input:
//     vIn: vector to be quantized
//     fIn: bit width of fractional part of quantized input LLR
//     wIn: bit width of quantized input LLR
//
// Return:
//     quantized input LLR data
//----------------------------------------------------------
static vector<int> quantizeLLR(const vector<double>& vIn, int fIn, int wIn)
{
    const int inSc = (1 << fIn);
    const int inMax = (1 << (wIn - 1)) - 1;
    const int inMin = -inMax;

    int n = vIn.size();
    vector<int> vOut(n);
    for (int i = 0; i < n; i++) {
        vOut[i] = max(min(static_cast<int>(vIn[i] * inSc + 0.5), inMax), inMin);
    }
    return vOut;
}


//----------------------------------------------------------
// Right rotate vector
//
// Inout:
//     vec: vector to be rotated
//
// Input:
//     sh: right rotate shift number, must be non-negative
//----------------------------------------------------------
static void rotateVector(vector<int>& vec, int sh)
{
    rotate(vec.begin(), vec.begin() + sh, vec.end());
}


//----------------------------------------------------------
// Parity check for LQ using base PCM
//
// Input:
//     vLQ: post LLR data of code
//
// Return:
//     Parity check result, true: pass, false: fail
//----------------------------------------------------------
static bool parityCheckBase(const vector<int>& vLQ, const PcmBase& pcm)
{
    int n = pcm.nb * pcm.z;
    int r = pcm.rb * pcm.z;
    vector<int> vLQHard(n);
    vector<int> vPc(r);
    vector<int> t;

    for (int i = 0; i < n; i++)
        vLQHard[i] = (vLQ[i] < 0) ? 1 : 0;

    for (int j = 0; j < pcm.nb; j++) {
        for (int i = 0; i < pcm.rb; i++) {
            int sh = pcm.base[i * pcm.nb + j];
            if (sh >= 0) {
                t.assign(vLQHard.begin() + j * pcm.z, vLQHard.begin() + (j + 1) * pcm.z);
                rotateVector(t, sh);
                for (int ii = 0; ii < pcm.z; ii++)
                    vPc[i * pcm.z + ii] = (vPc[i * pcm.z + ii] + t[ii]) % 2;
            }
        }
    }

    for (int i = 0; i < r; i++) {
        if (vPc[i] == 1)
            return false;
    }
    return true;
}


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
vector<int> ldpcDecodeHwCore(const vector<int>& dataIn,
                             const PcmBase& pcm, int maxIter,
                             int scSel, bool earlyExit,
                             const HwConfig& cfgHw,
                             int& numIter, bool& pc)
{
    int n = pcm.nb * pcm.z;

    if (dataIn.size() != static_cast<vector<int>::size_type>(n)) {
        cerr << "Error: Invalid input data size" << dataIn.size()
             << ", should be " << n << endl;
        exit(EXIT_FAILURE);
    }

    if (maxIter <= 0) {
        cerr << "Error: Invalid input maxIter" << maxIter
             << ", should be positive integer" << endl;
        exit(EXIT_FAILURE);
    }

    if (scSel != 0 && scSel != 1) {
        cerr << "Error: Invalid input scSel" << scSel
             << ", should be 0 or 1" << endl;
        exit(EXIT_FAILURE);
    }

    const int scInt = 12 + scSel;
    const int osInt = static_cast<int>(0.5 * (1 << cfgHw.F_IN) + 0.5);
    const int rMax = (1 << (cfgHw.W_CHK - 1)) - 1;
    const int rMin = -rMax;
    const int qMax = (1 << (cfgHw.W_VAR - 1)) - 1;
    const int qMin = -qMax;

    vector<int> vLQ(n);
    vector<int> vLr(pcm.rb * n);
    vector<int> prodLqSgn(pcm.z);
    vector<int> vLqAbsMin(pcm.z);
    vector<int> vLqAbsMinIdx(pcm.z);
    vector<int> vLqAbsMin2(pcm.z);

    // Initialize variable nodes
    for (int i = 0; i < n; i++)
        vLQ[i] = dataIn[i];

    // Decode iteratively
    numIter = 0;
    pc = false;
    for (int iter = 1; iter <= maxIter; iter++) {
        numIter++;

        // Layered decoding
        for (int i = 0; i < pcm.rb; i++) {
            // Update check nodes and variable nodes values for each layer
            fill(prodLqSgn.begin(), prodLqSgn.end(), 1);
            fill(vLqAbsMin.begin(), vLqAbsMin.end(), qMax);
            fill(vLqAbsMin2.begin(), vLqAbsMin2.end(), qMax);

            for (int j = 0; j < pcm.nb; j++) {
                int sh = pcm.base[i * pcm.nb + j];
                if (sh < 0)
                    continue;
                for (int ii = 0; ii < pcm.z; ii++) {
                    int idx = j * pcm.z + (ii + sh) % pcm.z;
                    int lq = vLQ[idx] - vLr[i * n + idx];
                    lq = max(min(lq, qMax), qMin);
                    int lqAbs = abs(lq);
                    if (lq < 0)
                        prodLqSgn[ii] = -prodLqSgn[ii];
                    if (lqAbs <= vLqAbsMin[ii]) {
                        vLqAbsMin2[ii] = vLqAbsMin[ii];
                        vLqAbsMin[ii] = lqAbs;
                        vLqAbsMinIdx[ii] = idx;
                    } else if (lqAbs <= vLqAbsMin2[ii]) {
                        vLqAbsMin2[ii] = lqAbs;
                    }
                }
            }

            for (int j = 0; j < pcm.nb; j++) {
                int sh = pcm.base[i * pcm.nb + j];
                if (sh < 0)
                    continue;
                for (int ii = 0; ii < pcm.z; ii++) {
                    int idx = j * pcm.z + (ii + sh) % pcm.z;
                    int lq = vLQ[idx] - vLr[i * n + idx];
                    lq = max(min(lq, qMax), qMin);
                    int lr = (lq < 0) ? -prodLqSgn[ii] : prodLqSgn[ii];
                    int lqAbsMin = (vLqAbsMinIdx[ii] == idx) ? vLqAbsMin2[ii] : vLqAbsMin[ii];
                    if (cfgHw.MS_ALG == 0)    // MS
                        lr *= lqAbsMin;
                    else if (cfgHw.MS_ALG == 1)    // NMS
                        lr *= (lqAbsMin * scInt + 8) / 16;
                    else if (cfgHw.MS_ALG == 2)    // OMS
                        lr *= max(lqAbsMin - osInt, 0);
                    vLr[i * n + idx] = max(min(lr, rMax), rMin);
                    vLQ[idx] = max(min(lq + lr, qMax), qMin);
                }
            }
        }

        // Parity checks
        if (cfgHw.HAS_PC) {
            if (earlyExit) {
                pc = parityCheckBase(vLQ, pcm);
                if (pc)
                    break;
            }
        }
    }

    // Output hard decision of information bits
    int szMsg = (pcm.nb - pcm.rb) * pcm.z;
    vector<int> y(szMsg);
    for (int i = 0; i < szMsg; i++)
        y[i] = (vLQ[i] < 0) ? 1 : 0;
    return y;
}


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
vector<int> ldpcDecodeHw(const vector<double>& dataIn,
                         CodeMode mode, int maxIter,
                         int scSel, bool earlyExit,
                         const HwConfig& cfgHw,
                         int& numIter, bool& pc)
{
    int idx = static_cast<int>(mode);
    vector<int> dataQ = quantizeLLR(dataIn, cfgHw.F_IN, cfgHw.W_IN);
    PcmBase pcm = rowPermutePcmBase(Hldpc[idx], RPldpc[idx]);
    return ldpcDecodeHwCore(dataQ, pcm, maxIter, scSel, earlyExit, cfgHw, numIter, pc);
}
