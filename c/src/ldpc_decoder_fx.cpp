//==============================================================================
// ldpc_decoder_fx.cpp
//
// LDPC decoder (fixed-point) implementation.
//------------------------------------------------------------------------------
// Copyright (c) 2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


#include "ldpc_decoder_fx.h"
#include <cstdlib>
#include <cmath>
#include <iostream>
#include <utility>
#include <algorithm>

using namespace std;


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
    vector<int> vLQHard(n);
    vector<int> vParity0(pcm.z);
    vector<int> t;

    for (int i = 0; i < n; i++)
        vLQHard[i] = (vLQ[i] < 0) ? 1 : 0;

    for (int i = 0; i < pcm.rb; i++) {
        fill(vParity0.begin(), vParity0.end(), 0);
        for (int j = 0; j < pcm.nb; j++) {
            int sh = pcm.base[i * pcm.nb + j];
            if (sh >= 0) {
                t.assign(vLQHard.begin() + j * pcm.z, vLQHard.begin() + (j + 1) * pcm.z);
                rotateVector(t, sh);
                for (int ii = 0; ii < pcm.z; ii++)
                    vParity0[ii] = (vParity0[ii] + t[ii]) % 2;
            }
        }
        for (int i = 0; i < pcm.z; i++) {
            if (vParity0[i] == 1)
                return false;
        }
    }

    return true;
}


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
vector<int> ldpcDecodeLNMSFxCore(const vector<int>& dataIn,
                                 const PcmBase& pcm, int maxIter,
                                 int scInt, bool earlyExit,
                                 const FxConfig& cfgFx,
                                 int& numIter)
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

    if (scInt <= 0 || scInt > 16) {
        cerr << "Error: Invalid input scInt" << scInt
             << ", should in range [1, 16]" << endl;
        exit(EXIT_FAILURE);
    }

    const int rMax = (1 << (cfgFx.W_CHK - 1)) - 1;
    const int rMin = -rMax;
    const int qMax = (1 << (cfgFx.W_VAR - 1)) - 1;
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
                    lr *= (lqAbsMin * scInt + 8) / 16;
                    vLr[i * n + idx] = max(min(lr, rMax), rMin);
                    vLQ[idx] = max(min(lq + lr, qMax), qMin);
                }
            }
        }

        // Parity checks
        if (earlyExit) {
            if (parityCheckBase(vLQ, pcm))
                break;
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
vector<int> ldpcDecodeLNMSFx(const vector<double>& dataIn,
                             CodeMode mode, int maxIter,
                             double sc, bool earlyExit,
                             const FxConfig& cfgFx,
                             int& numIter)
{
    int idxHldpc = static_cast<int>(mode);
    vector<int> dataQ = quantizeLLR(dataIn, cfgFx.F_IN, cfgFx.W_IN);
    int scInt = static_cast<int>(sc * 16 + 0.5);
    return ldpcDecodeLNMSFxCore(dataQ, Hldpc[idxHldpc], maxIter, scInt, earlyExit, cfgFx, numIter);
}


//----------------------------------------------------------
// LDPC decoder core with layered offset minimum-sum algorithm (fixed-point)
//
// Input:
//     dataIn: demapped LLR data
//     pcm: parity check matrix
//     maxIter: maximum number of decoding iterations
//     osInt: quantized offset
//     earlyExit: whether decoding terminates after all parity checks are satisfied
//     cfgFx: configuration object for fixed-point
//
// Output:
//     numIter: actual number of iterations performed
//
// Return:
//     decoded message data bits, value is 0 or 1
//----------------------------------------------------------
vector<int> ldpcDecodeLOMSFxCore(const vector<int>& dataIn,
                                 const PcmBase& pcm, int maxIter,
                                 int osInt, bool earlyExit,
                                 const FxConfig& cfgFx,
                                 int& numIter)
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

    if (osInt < 0) {
        cerr << "Error: Invalid input osInt" << osInt
             << ", should be nonnegative" << endl;
        exit(EXIT_FAILURE);
    }

    const int rMax = (1 << (cfgFx.W_CHK - 1)) - 1;
    const int rMin = -rMax;
    const int qMax = (1 << (cfgFx.W_VAR - 1)) - 1;
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
                    lr *= max(lqAbsMin - osInt, 0);
                    vLr[i * n + idx] = max(min(lr, rMax), rMin);
                    vLQ[idx] = max(min(lq + lr, qMax), qMin);
                }
            }
        }

        // Parity checks
        if (earlyExit) {
            if (parityCheckBase(vLQ, pcm))
                break;
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
// LDPC decoder with layered offset minimum-sum algorithm (fixed-point)
//
// Input:
//     dataIn: demapped LLR data
//     mode: mode of codeword length and code rate
//     maxIter: maximum number of decoding iterations
//     os: offset
//     earlyExit: whether decoding terminates after all parity checks are satisfied
//     cfgFx: configuration object for fixed-point
//
// Output:
//     numIter: actual number of iterations performed
//
// Return:
//     decoded message data bits, value is 0 or 1
//----------------------------------------------------------
vector<int> ldpcDecodeLOMSFx(const vector<double>& dataIn,
                             CodeMode mode, int maxIter,
                             double os, bool earlyExit,
                             const FxConfig& cfgFx,
                             int& numIter)
{
    int idxHldpc = static_cast<int>(mode);
    vector<int> dataQ = quantizeLLR(dataIn, cfgFx.F_IN, cfgFx.W_IN);
    int osInt = static_cast<int>(os * (1 << cfgFx.F_IN) + 0.5);
    return ldpcDecodeLOMSFxCore(dataQ, Hldpc[idxHldpc], maxIter, osInt, earlyExit, cfgFx, numIter);
}
