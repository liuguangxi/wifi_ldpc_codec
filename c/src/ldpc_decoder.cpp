//==============================================================================
// ldpc_decoder.cpp
//
// LDPC decoder implementation.
//------------------------------------------------------------------------------
// Copyright (c) 2019 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


#include "ldpc_decoder.h"
#include <cstdlib>
#include <cmath>
#include <iostream>
#include <utility>
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
// Parity check for LQ
//
// Input:
//     vLQ: post LLR data of code
//
// Return:
//     Parity check result, true: pass, false: fail
//----------------------------------------------------------
static bool parityCheck(const vector<double>& vLQ, const PcmGraph& pcm)
{
    int nz = pcm.rows.size();
    vector<int> vLQHard(pcm.n);
    vector<int> vParity(pcm.r);

    for (int i = 0; i < pcm.n; i++)
        vLQHard[i] = (vLQ[i] < 0) ? 1 : 0;

    fill(vParity.begin(), vParity.end(), 0);
    for (int i = 0; i < nz; i++) {
        if (vLQHard[pcm.cols[i]] == 1)
            vParity[pcm.rows[i]] = 1 - vParity[pcm.rows[i]];
    }

    for (int i = 0; i < pcm.r; i++) {
        if (vParity[i] == 1)
            return false;
    }
    return true;
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
static bool parityCheckBase(const vector<double>& vLQ, const PcmBase& pcm)
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
            t.assign(vLQHard.begin() + j * pcm.z, vLQHard.begin() + (j + 1) * pcm.z);
            rotateVector(t, pcm.base[i * pcm.nb + j]);
            for (int ii = 0; ii < pcm.z; ii++)
                vParity0[ii] = (vParity0[ii] + t[ii]) % 2;
        }
        for (int i = 0; i < pcm.z; i++) {
            if (vParity0[i] == 1)
                return false;
        }
    }

    return true;
}


//----------------------------------------------------------
// Get parity check matrix graph
//
// Input:
//     idxHldpc: index of Hldpc
//
// Return:
//     Parity check matrix graph for Hldpc with index idxHldpc
//----------------------------------------------------------
PcmGraph getPcmGraph(int idxHldpc)
{
    const PcmBase& h = Hldpc[idxHldpc];
    int r = h.rb * h.z;
    int n = h.nb * h.z;
    PcmGraph pcm;
    vector<pair<int, int>> vpos;
    int szvpos;

    pcm.r = r;
    pcm.n = n;

    for (int i = 0; i < h.rb; i++) {
        for (int j = 0; j < h.nb; j++) {
            int sh = h.base[i * h.nb + j];
            if (sh == -1)
                continue;
            for (int k = 0; k < h.z; k++) {
                int rowk = i * h.z + k;
                int colk = j * h.z + (k + sh) % h.z;
                vpos.push_back(make_pair(colk, rowk));
            }
        }
    }
    szvpos = vpos.size();

    sort(vpos.begin(), vpos.end());
    for (int i = 0; i < szvpos; i++) {
        pcm.cols.push_back(vpos[i].first);
        pcm.rows.push_back(vpos[i].second);
    }

    return pcm;
}


//----------------------------------------------------------
// LDPC decoder core with sum-product algorithm
//
// Input:
//     dataIn: demapped LLR data
//     pcm: parity check matrix graph
//     maxIter: maximum number of decoding iterations
//     earlyExit: whether decoding terminates after all parity checks are satisfied
//
// Output:
//     numIter: actual number of iterations performed
//
// Return:
//     decoded message data bits, value is 0 or 1
//----------------------------------------------------------
vector<int> ldpcDecodeSPCore(const vector<double>& dataIn,
                             const PcmGraph& pcm, int maxIter, bool earlyExit,
                             int &numIter)
{
    if (dataIn.size() != static_cast<vector<int>::size_type>(pcm.n)) {
        cerr << "Error: Invalid input data size" << dataIn.size()
             << ", should be " << pcm.n << endl;
        exit(EXIT_FAILURE);
    }

    if (maxIter <= 0) {
        cerr << "Error: Invalid input maxIter" << maxIter
             << ", should be positive integer" << endl;
        exit(EXIT_FAILURE);
    }

    int nz = pcm.rows.size();
    vector<double> vLq(nz);
    vector<double> prodLq(pcm.r);
    vector<double> vLr(nz);
    vector<double> vLQ(pcm.n);

    // Initialize variable nodes
    for (int i = 0; i < nz; i++)
        vLq[i] = dataIn[pcm.cols[i]];

    // Decode iteratively
    numIter = 0;
    for (int iter = 1; iter <= maxIter; iter++) {
        numIter++;

        // Calculate check nodes values from variable node values
        for (int i = 0; i < nz; i++) {
            double lq = tanh(vLq[i] / 2.0);
            lq = (lq >= 0) ? max(1e-9, lq) : min(-1e-9, lq);
            vLq[i] = lq;
        }
        fill(prodLq.begin(), prodLq.end(), 1.0);
        for (int i = 0; i < nz; i++)
            prodLq[pcm.rows[i]] *= vLq[i];
        for (int i = 0; i < nz; i++) {
            double lr = prodLq[pcm.rows[i]] / vLq[i];
            lr = 2 * atanh(max(min(lr, 0.999999999999), -0.999999999999));
            vLr[i] = lr;
        }

        // Calculate variable nodes values from check node values
        for (int i = 0; i < pcm.n; i++)
            vLQ[i] = dataIn[i];
        for (int i = 0; i < nz; i++)
            vLQ[pcm.cols[i]] += vLr[i];
        for (int i = 0; i < nz; i++)
            vLq[i] = vLQ[pcm.cols[i]] - vLr[i];

        // Parity checks
        if (earlyExit) {
            if (parityCheck(vLQ, pcm))
                break;
        }
    }

    // Output hard decision of information bits
    int szMsg = pcm.n - pcm.r;
    vector<int> y(szMsg);
    for (int i = 0; i < szMsg; i++)
        y[i] = (vLQ[i] < 0) ? 1 : 0;
    return y;
}


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
vector<int> ldpcDecodeSP(const vector<double>& dataIn,
                         CodeMode mode, int maxIter, bool earlyExit,
                         int &numIter)
{
    int idxHldpc = static_cast<int>(mode);
    PcmGraph pcm = getPcmGraph(idxHldpc);
    return ldpcDecodeSPCore(dataIn, pcm, maxIter, earlyExit, numIter);
}


//----------------------------------------------------------
// LDPC decoder core with minimum-sum algorithm
//
// Input:
//     dataIn: demapped LLR data
//     pcm: parity check matrix graph
//     maxIter: maximum number of decoding iterations
//     earlyExit: whether decoding terminates after all parity checks are satisfied
//
// Output:
//     numIter: actual number of iterations performed
//
// Return:
//     decoded message data bits, value is 0 or 1
//----------------------------------------------------------
vector<int> ldpcDecodeMSCore(const vector<double>& dataIn,
                             const PcmGraph& pcm, int maxIter, bool earlyExit,
                             int &numIter)
{
    if (dataIn.size() != static_cast<vector<int>::size_type>(pcm.n)) {
        cerr << "Error: Invalid input data size" << dataIn.size()
             << ", should be " << pcm.n << endl;
        exit(EXIT_FAILURE);
    }

    if (maxIter <= 0) {
        cerr << "Error: Invalid input maxIter" << maxIter
             << ", should be positive integer" << endl;
        exit(EXIT_FAILURE);
    }

    int nz = pcm.rows.size();
    vector<double> vLq(nz);
    vector<int> vLqSgn(nz);
    vector<double> vLqAbs(nz);
    vector<int> prodLqSgn(pcm.r);
    vector<double> vLqAbsMin(pcm.r);
    vector<int> vLqAbsMinIdx(pcm.r);
    vector<double> vLqAbsMin2(pcm.r);
    vector<double> vLr(nz);
    vector<double> vLQ(pcm.n);

    // Initialize variable nodes
    for (int i = 0; i < nz; i++)
        vLq[i] = dataIn[pcm.cols[i]];

    // Decode iteratively
    numIter = 0;
    for (int iter = 1; iter <= maxIter; iter++) {
        numIter++;

        // Calculate check nodes values from variable node values
        for (int i = 0; i < nz; i++) {
            vLqSgn[i] = (vLq[i] >= 0) ? 1 : -1;
            vLqAbs[i] = abs(vLq[i]);
        }
        fill(prodLqSgn.begin(), prodLqSgn.end(), 1);
        fill(vLqAbsMin.begin(), vLqAbsMin.end(), 1e12);
        fill(vLqAbsMin2.begin(), vLqAbsMin2.end(), 1e12);
        for (int i = 0; i < nz; i++) {
            int rowsi = pcm.rows[i];
            prodLqSgn[rowsi] *= vLqSgn[i];
            if (vLqAbs[i] < vLqAbsMin[rowsi]) {
                vLqAbsMin2[rowsi] = vLqAbsMin[rowsi];
                vLqAbsMin[rowsi] = vLqAbs[i];
                vLqAbsMinIdx[rowsi] = i;
            } else if (vLqAbs[i] < vLqAbsMin2[rowsi]) {
                vLqAbsMin2[rowsi] = vLqAbs[i];
            }
        }
        for (int i = 0; i < nz; i++) {
            int rowsi = pcm.rows[i];
            double lqAbsMin = (vLqAbsMinIdx[rowsi] == i) ?
                              vLqAbsMin2[rowsi] : vLqAbsMin[rowsi];
            vLr[i] = prodLqSgn[rowsi] * vLqSgn[i] * lqAbsMin;
        }

        // Calculate variable nodes values from check node values
        for (int i = 0; i < pcm.n; i++)
            vLQ[i] = dataIn[i];
        for (int i = 0; i < nz; i++)
            vLQ[pcm.cols[i]] += vLr[i];
        for (int i = 0; i < nz; i++)
            vLq[i] = vLQ[pcm.cols[i]] - vLr[i];

        // Parity checks
        if (earlyExit) {
            if (parityCheck(vLQ, pcm))
                break;
        }
    }

    // Output hard decision of information bits
    int szMsg = pcm.n - pcm.r;
    vector<int> y(szMsg);
    for (int i = 0; i < szMsg; i++)
        y[i] = (vLQ[i] < 0) ? 1 : 0;
    return y;
}


//----------------------------------------------------------
// LDPC decoder with minimum-sum algorithm
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
vector<int> ldpcDecodeMS(const vector<double>& dataIn,
                         CodeMode mode, int maxIter, bool earlyExit,
                         int &numIter)
{
    int idxHldpc = static_cast<int>(mode);
    PcmGraph pcm = getPcmGraph(idxHldpc);
    return ldpcDecodeMSCore(dataIn, pcm, maxIter, earlyExit, numIter);
}


//----------------------------------------------------------
// LDPC decoder core with normalized minimum-sum algorithm
//
// Input:
//     dataIn: demapped LLR data
//     pcm: parity check matrix graph
//     maxIter: maximum number of decoding iterations
//     sc: scaling factor
//     earlyExit: whether decoding terminates after all parity checks are satisfied
//
// Output:
//     numIter: actual number of iterations performed
//
// Return:
//     decoded message data bits, value is 0 or 1
//----------------------------------------------------------
vector<int> ldpcDecodeNMSCore(const vector<double>& dataIn,
                              const PcmGraph& pcm, int maxIter,
                              double sc, bool earlyExit,
                              int &numIter)
{
    if (dataIn.size() != static_cast<vector<int>::size_type>(pcm.n)) {
        cerr << "Error: Invalid input data size" << dataIn.size()
             << ", should be " << pcm.n << endl;
        exit(EXIT_FAILURE);
    }

    if (maxIter <= 0) {
        cerr << "Error: Invalid input maxIter" << maxIter
             << ", should be positive integer" << endl;
        exit(EXIT_FAILURE);
    }

    if (sc <= 0 || sc > 1) {
        cerr << "Error: Invalid input sc" << sc
             << ", should in range (0, 1]" << endl;
        exit(EXIT_FAILURE);
    }

    int nz = pcm.rows.size();
    vector<double> vLq(nz);
    vector<int> vLqSgn(nz);
    vector<double> vLqAbs(nz);
    vector<int> prodLqSgn(pcm.r);
    vector<double> vLqAbsMin(pcm.r);
    vector<int> vLqAbsMinIdx(pcm.r);
    vector<double> vLqAbsMin2(pcm.r);
    vector<double> vLr(nz);
    vector<double> vLQ(pcm.n);

    // Initialize variable nodes
    for (int i = 0; i < nz; i++)
        vLq[i] = dataIn[pcm.cols[i]];

    // Decode iteratively
    numIter = 0;
    for (int iter = 1; iter <= maxIter; iter++) {
        numIter++;

        // Calculate check nodes values from variable node values
        for (int i = 0; i < nz; i++) {
            vLqSgn[i] = (vLq[i] >= 0) ? 1 : -1;
            vLqAbs[i] = abs(vLq[i]);
        }
        fill(prodLqSgn.begin(), prodLqSgn.end(), 1);
        fill(vLqAbsMin.begin(), vLqAbsMin.end(), 1e12);
        fill(vLqAbsMin2.begin(), vLqAbsMin2.end(), 1e12);
        for (int i = 0; i < nz; i++) {
            int rowsi = pcm.rows[i];
            prodLqSgn[rowsi] *= vLqSgn[i];
            if (vLqAbs[i] < vLqAbsMin[rowsi]) {
                vLqAbsMin2[rowsi] = vLqAbsMin[rowsi];
                vLqAbsMin[rowsi] = vLqAbs[i];
                vLqAbsMinIdx[rowsi] = i;
            } else if (vLqAbs[i] < vLqAbsMin2[rowsi]) {
                vLqAbsMin2[rowsi] = vLqAbs[i];
            }
        }
        for (int i = 0; i < nz; i++) {
            int rowsi = pcm.rows[i];
            double lqAbsMin = (vLqAbsMinIdx[rowsi] == i) ?
                              vLqAbsMin2[rowsi] : vLqAbsMin[rowsi];
            vLr[i] = prodLqSgn[rowsi] * vLqSgn[i] * lqAbsMin * sc;
        }

        // Calculate variable nodes values from check node values
        for (int i = 0; i < pcm.n; i++)
            vLQ[i] = dataIn[i];
        for (int i = 0; i < nz; i++)
            vLQ[pcm.cols[i]] += vLr[i];
        for (int i = 0; i < nz; i++)
            vLq[i] = vLQ[pcm.cols[i]] - vLr[i];

        // Parity checks
        if (earlyExit) {
            if (parityCheck(vLQ, pcm))
                break;
        }
    }

    // Output hard decision of information bits
    int szMsg = pcm.n - pcm.r;
    vector<int> y(szMsg);
    for (int i = 0; i < szMsg; i++)
        y[i] = (vLQ[i] < 0) ? 1 : 0;
    return y;
}


//----------------------------------------------------------
// LDPC decoder with normalized minimum-sum algorithm
//
// Input:
//     dataIn: demapped LLR data
//     mode: mode of codeword length and code rate
//     maxIter: maximum number of decoding iterations
//     sc: scaling factor
//     earlyExit: whether decoding terminates after all parity checks are satisfied
//
// Output:
//     numIter: actual number of iterations performed
//
// Return:
//     decoded message data bits, value is 0 or 1
//----------------------------------------------------------
vector<int> ldpcDecodeNMS(const vector<double>& dataIn,
                          CodeMode mode, int maxIter,
                          double sc, bool earlyExit,
                          int &numIter)
{
    int idxHldpc = static_cast<int>(mode);
    PcmGraph pcm = getPcmGraph(idxHldpc);
    return ldpcDecodeNMSCore(dataIn, pcm, maxIter, sc, earlyExit, numIter);
}


//----------------------------------------------------------
// LDPC decoder core with offset minimum-sum algorithm
//
// Input:
//     dataIn: demapped LLR data
//     pcm: parity check matrix graph
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
vector<int> ldpcDecodeOMSCore(const vector<double>& dataIn,
                              const PcmGraph& pcm, int maxIter,
                              double os, bool earlyExit,
                              int &numIter)
{
    if (dataIn.size() != static_cast<vector<int>::size_type>(pcm.n)) {
        cerr << "Error: Invalid input data size" << dataIn.size()
             << ", should be " << pcm.n << endl;
        exit(EXIT_FAILURE);
    }

    if (maxIter <= 0) {
        cerr << "Error: Invalid input maxIter" << maxIter
             << ", should be positive integer" << endl;
        exit(EXIT_FAILURE);
    }

    if (os < 0) {
        cerr << "Error: Invalid input os" << os
             << ", should be nonnegative" << endl;
        exit(EXIT_FAILURE);
    }

    int nz = pcm.rows.size();
    vector<double> vLq(nz);
    vector<int> vLqSgn(nz);
    vector<double> vLqAbs(nz);
    vector<int> prodLqSgn(pcm.r);
    vector<double> vLqAbsMin(pcm.r);
    vector<int> vLqAbsMinIdx(pcm.r);
    vector<double> vLqAbsMin2(pcm.r);
    vector<double> vLr(nz);
    vector<double> vLQ(pcm.n);

    // Initialize variable nodes
    for (int i = 0; i < nz; i++)
        vLq[i] = dataIn[pcm.cols[i]];

    // Decode iteratively
    numIter = 0;
    for (int iter = 1; iter <= maxIter; iter++) {
        numIter++;

        // Calculate check nodes values from variable node values
        for (int i = 0; i < nz; i++) {
            vLqSgn[i] = (vLq[i] >= 0) ? 1 : -1;
            vLqAbs[i] = abs(vLq[i]);
        }
        fill(prodLqSgn.begin(), prodLqSgn.end(), 1);
        fill(vLqAbsMin.begin(), vLqAbsMin.end(), 1e12);
        fill(vLqAbsMin2.begin(), vLqAbsMin2.end(), 1e12);
        for (int i = 0; i < nz; i++) {
            int rowsi = pcm.rows[i];
            prodLqSgn[rowsi] *= vLqSgn[i];
            if (vLqAbs[i] < vLqAbsMin[rowsi]) {
                vLqAbsMin2[rowsi] = vLqAbsMin[rowsi];
                vLqAbsMin[rowsi] = vLqAbs[i];
                vLqAbsMinIdx[rowsi] = i;
            } else if (vLqAbs[i] < vLqAbsMin2[rowsi]) {
                vLqAbsMin2[rowsi] = vLqAbs[i];
            }
        }
        for (int i = 0; i < nz; i++) {
            int rowsi = pcm.rows[i];
            double lqAbsMin = (vLqAbsMinIdx[rowsi] == i) ?
                              vLqAbsMin2[rowsi] : vLqAbsMin[rowsi];
            vLr[i] = prodLqSgn[rowsi] * vLqSgn[i] * max(lqAbsMin - os, 0.0);
        }

        // Calculate variable nodes values from check node values
        for (int i = 0; i < pcm.n; i++)
            vLQ[i] = dataIn[i];
        for (int i = 0; i < nz; i++)
            vLQ[pcm.cols[i]] += vLr[i];
        for (int i = 0; i < nz; i++)
            vLq[i] = vLQ[pcm.cols[i]] - vLr[i];

        // Parity checks
        if (earlyExit) {
            if (parityCheck(vLQ, pcm))
                break;
        }
    }

    // Output hard decision of information bits
    int szMsg = pcm.n - pcm.r;
    vector<int> y(szMsg);
    for (int i = 0; i < szMsg; i++)
        y[i] = (vLQ[i] < 0) ? 1 : 0;
    return y;
}


//----------------------------------------------------------
// LDPC decoder with offset minimum-sum algorithm
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
vector<int> ldpcDecodeOMS(const vector<double>& dataIn,
                          CodeMode mode, int maxIter,
                          double os, bool earlyExit,
                          int &numIter)
{
    int idxHldpc = static_cast<int>(mode);
    PcmGraph pcm = getPcmGraph(idxHldpc);
    return ldpcDecodeOMSCore(dataIn, pcm, maxIter, os, earlyExit, numIter);
}


//----------------------------------------------------------
// LDPC decoder core with layered normalized minimum-sum algorithm
//
// Input:
//     dataIn: demapped LLR data
//     pcm: parity check matrix graph
//     maxIter: maximum number of decoding iterations
//     sc: scaling factor
//     earlyExit: whether decoding terminates after all parity checks are satisfied
//
// Output:
//     numIter: actual number of iterations performed
//
// Return:
//     decoded message data bits, value is 0 or 1
//----------------------------------------------------------
std::vector<int> ldpcDecodeLNMSCore(const std::vector<double>& dataIn,
                                    const PcmBase& pcm, int maxIter,
                                    double sc, bool earlyExit,
                                    int &numIter)
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

    if (sc <= 0 || sc > 1) {
        cerr << "Error: Invalid input sc" << sc
             << ", should in range (0, 1]" << endl;
        exit(EXIT_FAILURE);
    }

    vector<double> vLQ(n);
    vector<double> vLr(pcm.rb * n);
    vector<int> prodLqSgn(pcm.z);
    vector<double> vLqAbsMin(pcm.z);
    vector<int> vLqAbsMinIdx(pcm.z);
    vector<double> vLqAbsMin2(pcm.z);

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
            fill(vLqAbsMin.begin(), vLqAbsMin.end(), 1e12);
            fill(vLqAbsMin2.begin(), vLqAbsMin2.end(), 1e12);

            for (int j = 0; j < pcm.nb; j++) {
                int sh = pcm.base[i * pcm.nb + j];
                if (sh < 0)
                    continue;
                for (int ii = 0; ii < pcm.z; ii++) {
                    int idx = j * pcm.z + (ii + sh) % pcm.z;
                    double lq = vLQ[idx] - vLr[i * n + idx];
                    double lqAbs = abs(lq);
                    if (lq < 0)
                        prodLqSgn[ii] = -prodLqSgn[ii];
                    if (lqAbs < vLqAbsMin[ii]) {
                        vLqAbsMin2[ii] = vLqAbsMin[ii];
                        vLqAbsMin[ii] = lqAbs;
                        vLqAbsMinIdx[ii] = idx;
                    } else if (lqAbs < vLqAbsMin2[ii]) {
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
                    double lq = vLQ[idx] - vLr[i * n + idx];
                    double lr = (lq < 0) ? -prodLqSgn[ii] : prodLqSgn[ii];
                    double lqAbsMin = (vLqAbsMinIdx[ii] == idx) ?
                                      vLqAbsMin2[ii] : vLqAbsMin[ii];
                    lr *= lqAbsMin * sc;
                    vLr[i * n + idx] = lr;
                    vLQ[idx] = lq + lr;
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
// LDPC decoder with layered normalized minimum-sum algorithm
//
// Input:
//     dataIn: demapped LLR data
//     mode: mode of codeword length and code rate
//     maxIter: maximum number of decoding iterations
//     sc: scaling factor
//     earlyExit: whether decoding terminates after all parity checks are satisfied
//
// Output:
//     numIter: actual number of iterations performed
//
// Return:
//     decoded message data bits, value is 0 or 1
//----------------------------------------------------------
std::vector<int> ldpcDecodeLNMS(const std::vector<double>& dataIn,
                                CodeMode mode, int maxIter,
                                double sc, bool earlyExit,
                                int &numIter)
{
    int idxHldpc = static_cast<int>(mode);
    return ldpcDecodeLNMSCore(dataIn, Hldpc[idxHldpc], maxIter, sc, earlyExit, numIter);
}


//----------------------------------------------------------
// LDPC decoder core with layered offset minimum-sum algorithm
//
// Input:
//     dataIn: demapped LLR data
//     pcm: parity check matrix graph
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
std::vector<int> ldpcDecodeLOMSCore(const std::vector<double>& dataIn,
                                    const PcmBase& pcm, int maxIter,
                                    double os, bool earlyExit,
                                    int &numIter)
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

    if (os < 0) {
        cerr << "Error: Invalid input os" << os
             << ", should be nonnegative" << endl;
        exit(EXIT_FAILURE);
    }

    vector<double> vLQ(n);
    vector<double> vLr(pcm.rb * n);
    vector<int> prodLqSgn(pcm.z);
    vector<double> vLqAbsMin(pcm.z);
    vector<int> vLqAbsMinIdx(pcm.z);
    vector<double> vLqAbsMin2(pcm.z);

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
            fill(vLqAbsMin.begin(), vLqAbsMin.end(), 1e12);
            fill(vLqAbsMin2.begin(), vLqAbsMin2.end(), 1e12);

            for (int j = 0; j < pcm.nb; j++) {
                int sh = pcm.base[i * pcm.nb + j];
                if (sh < 0)
                    continue;
                for (int ii = 0; ii < pcm.z; ii++) {
                    int idx = j * pcm.z + (ii + sh) % pcm.z;
                    double lq = vLQ[idx] - vLr[i * n + idx];
                    double lqAbs = abs(lq);
                    if (lq < 0)
                        prodLqSgn[ii] = -prodLqSgn[ii];
                    if (lqAbs < vLqAbsMin[ii]) {
                        vLqAbsMin2[ii] = vLqAbsMin[ii];
                        vLqAbsMin[ii] = lqAbs;
                        vLqAbsMinIdx[ii] = idx;
                    } else if (lqAbs < vLqAbsMin2[ii]) {
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
                    double lq = vLQ[idx] - vLr[i * n + idx];
                    double lr = (lq < 0) ? -prodLqSgn[ii] : prodLqSgn[ii];
                    double lqAbsMin = (vLqAbsMinIdx[ii] == idx) ?
                                      vLqAbsMin2[ii] : vLqAbsMin[ii];
                    lr *= max(lqAbsMin - os, 0.0);
                    vLr[i * n + idx] = lr;
                    vLQ[idx] = lq + lr;
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
// LDPC decoder with layered offset minimum-sum algorithm
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
std::vector<int> ldpcDecodeLOMS(const std::vector<double>& dataIn,
                                CodeMode mode, int maxIter,
                                double os, bool earlyExit,
                                int &numIter)
{
    int idxHldpc = static_cast<int>(mode);
    return ldpcDecodeLOMSCore(dataIn, Hldpc[idxHldpc], maxIter, os, earlyExit, numIter);
}
